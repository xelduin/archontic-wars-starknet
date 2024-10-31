use astraplani::models::owner::Owner;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::Position;
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::vec2::{Vec2, Vec2Impl};
use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use astraplani::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

use astraplani::utils::testing::{world::spawn_world, spawners::spawn_quasar, spawners::spawn_star};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (IWorldDispatcher, ContractAddress, u32, u32, ICreationSystemsDispatcher) {
    let world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let creation_address = world
        .deploy_contract('salt', creation_systems::TEST_CLASS_HASH.try_into().unwrap());
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), creation_address);

    let player = contract_address_const::<'old_owner'>();

    let quasar_coords = Vec2 { x: 23, y: 32 };
    let emission_rate = 1_000_000;
    let quasar_mass = 1_000_000;
    let quasar_id = spawn_quasar(world, player, quasar_coords, emission_rate, quasar_mass);

    let far_star_coords = Vec2 { x: 42, y: 23 };
    let far_star_mass = 1_000;
    let far_star_id = spawn_star(world, player, far_star_coords, far_star_mass);

    set!(world, (LooshBalance { address: player, balance: 1_000_000_000_000_000 }));

    (world, player, quasar_id, far_star_id, creation_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_create_protostar_valid() {
    let (world, player, quasar_id, _, creation_dispatcher) = setup();

    set_contract_address(player);
    set_account_contract_address(player);

    let coords = Vec2 { x: 20, y: 21 };
    let protostar_id = creation_dispatcher.create_protostar(coords, quasar_id);

    let protostar_owner = get!(world, protostar_id, Owner);
    assert(protostar_owner.address == player, 'invalid owner');
    let protostar_coords = get!(world, protostar_id, Position);
    assert(protostar_coords.vec.is_equal(coords), 'invalid coords');
    let protostar_body = get!(world, protostar_id, CosmicBody);
    assert(protostar_body.body_type == CosmicBodyType::Protostar, 'invalid body type');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_create_protostar_no_loosh() {
    let (world, player, quasar_id, _, creation_dispatcher) = setup();

    set!(world, LooshBalance { address: player, balance: 0 });

    set_contract_address(player);
    set_account_contract_address(player);

    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_protostar(coords, quasar_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('coords are occupied', 'ENTRYPOINT_FAILED'))]
fn test_create_protostar_occupied_pos() {
    let (_, player, quasar_id, _, creation_dispatcher) = setup();

    set_contract_address(player);
    set_account_contract_address(player);

    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_protostar(coords, quasar_id);
    // Try to create anotheer one at the same position
    creation_dispatcher.create_protostar(coords, quasar_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid quasar id', 'ENTRYPOINT_FAILED'))]
fn test_create_protostar_not_in_quasar() {
    let (_, player, _, far_star_id, creation_dispatcher) = setup();

    set_contract_address(player);
    set_account_contract_address(player);

    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_protostar(coords, far_star_id);
}
