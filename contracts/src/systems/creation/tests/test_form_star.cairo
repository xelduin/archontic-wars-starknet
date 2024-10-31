use astraplani::models::owner::Owner;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::Position;
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::incubation::Incubation;
use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_block_timestamp, set_contract_address, set_account_contract_address}
};
use starknet::contract_address_const;

use astraplani::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_quasar, spawners::spawn_star, spawners::spawn_protostar
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

const BASE_INCUBATION_PERIOD: u64 = 60 * 1000;

// Mock setup for the test
fn setup() -> (
    IWorldDispatcher, ContractAddress, ContractAddress, u32, u32, u64, ICreationSystemsDispatcher
) {
    let world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let creation_address = world
        .deploy_contract('salt', creation_systems::TEST_CLASS_HASH.try_into().unwrap());
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), creation_address);

    let protostar_owner = contract_address_const::<'protostar_owner'>();
    let not_protostar_owner = contract_address_const::<'not_protostar_owner'>();

    let quasar_coords = Vec2 { x: 23, y: 32 };
    let emission_rate = 1_000_000;
    let quasar_mass = 1_000_000;
    let quasar_id = spawn_quasar(world, protostar_owner, quasar_coords, emission_rate, quasar_mass);

    let protostar_coords = Vec2 { x: 42, y: 23 };
    let protostar_mass = 1_000;
    let creation_ts = get_block_timestamp();
    let end_ts = creation_ts + BASE_INCUBATION_PERIOD;

    let protostar_id = spawn_protostar(
        world, protostar_owner, protostar_coords, protostar_mass, creation_ts, end_ts
    );

    set!(world, (LooshBalance { address: protostar_owner, balance: 1_000_000_000_000_000 }));

    (
        world,
        protostar_owner,
        not_protostar_owner,
        quasar_id,
        protostar_id,
        end_ts,
        creation_dispatcher
    )
}

#[test]
#[available_gas(3000000000000)]
fn test_form_star_valid() {
    let (world, protostar_owner, _, _, protostar_id, end_ts, creation_dispatcher) = setup();

    set_contract_address(protostar_owner);
    set_account_contract_address(protostar_owner);

    set_block_timestamp(end_ts);

    creation_dispatcher.form_star(protostar_id);
    let protostar_body = get!(world, protostar_id, CosmicBody);
    assert(protostar_body.body_type == CosmicBodyType::Star, 'invalid body type');
    let protostar_incubation = get!(world, protostar_id, (Incubation));
    assert(protostar_incubation.end_ts == 0, 'still incubating');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_form_star_no_loosh() {
    let (world, protostar_owner, _, _, protostar_id, end_ts, creation_dispatcher) = setup();

    set!(world, LooshBalance { address: protostar_owner, balance: 0 });

    set_contract_address(protostar_owner);
    set_account_contract_address(protostar_owner);

    set_block_timestamp(end_ts);

    creation_dispatcher.form_star(protostar_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid protostar id', 'ENTRYPOINT_FAILED'))]
fn test_form_star_not_protostar() {
    let (_, protostar_owner, _, quasar_id, _, end_ts, creation_dispatcher) = setup();

    set_contract_address(protostar_owner);
    set_account_contract_address(protostar_owner);

    set_block_timestamp(end_ts);

    creation_dispatcher.form_star(quasar_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('caller must be owner', 'ENTRYPOINT_FAILED'))]
fn test_form_star_not_owner() {
    let (_, _, not_protostar_owner, _, protostar_id, end_ts, creation_dispatcher) = setup();

    set_contract_address(not_protostar_owner);
    set_account_contract_address(not_protostar_owner);

    set_block_timestamp(end_ts);

    creation_dispatcher.form_star(protostar_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('incubation not over', 'ENTRYPOINT_FAILED'))]
fn test_form_star_incubation_not_over() {
    let (_, protostar_owner, _, _, protostar_id, _, creation_dispatcher) = setup();

    set_contract_address(protostar_owner);
    set_account_contract_address(protostar_owner);

    creation_dispatcher.form_star(protostar_id);
}
