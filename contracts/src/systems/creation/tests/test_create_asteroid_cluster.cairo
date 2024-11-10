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
fn setup() -> (
    IWorldDispatcher, ContractAddress, ContractAddress, u32, u32, ICreationSystemsDispatcher
) {
    let world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let creation_address = world
        .deploy_contract('salt', creation_systems::TEST_CLASS_HASH.try_into().unwrap());
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), creation_address);

    let star_owner = contract_address_const::<'star_owner'>();
    let not_star_owner = contract_address_const::<'not_star_owner'>();

    let quasar_coords = Vec2 { x: 23, y: 32 };
    let emission_rate = 1_000_000;
    let quasar_mass = 1_000_000;
    let quasar_id = spawn_quasar(world, star_owner, quasar_coords, emission_rate, quasar_mass);

    let star_coords = Vec2 { x: 42, y: 23 };
    let star_mass = 1_000;
    let star_id = spawn_star(world, star_owner, star_coords, quasar_id, star_mass);

    set!(world, (LooshBalance { address: star_owner, balance: 1_000_000_000_000_000 }));

    (world, star_owner, not_star_owner, quasar_id, star_id, creation_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_create_asteroid_cluster_valid() {
    let (world, star_owner, _, _, star_id, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let coords = Vec2 { x: 20, y: 21 };
    let asteroid_cluster_id = creation_dispatcher.create_asteroid_cluster(coords, star_id);

    let asteroid_cluster_owner = get!(world, asteroid_cluster_id, Owner);
    assert(asteroid_cluster_owner.address == star_owner, 'invalid owner');
    let asteroid_cluster_coords = get!(world, asteroid_cluster_id, Position);
    assert(asteroid_cluster_coords.vec.is_equal(coords), 'invalid coords');
    let asteroid_cluster_body = get!(world, asteroid_cluster_id, CosmicBody);
    assert(asteroid_cluster_body.body_type == CosmicBodyType::AsteroidCluster, 'invalid body type');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_create_asteroid_cluster_no_loosh() {
    let (world, star_owner, _, _, star_id, creation_dispatcher) = setup();

    set!(world, LooshBalance { address: star_owner, balance: 0 });

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_asteroid_cluster(coords, star_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('caller must own star', 'ENTRYPOINT_FAILED'))]
fn test_create_asteroid_cluster_not_star_owner() {
    let (_, _, not_star_owner, _, star_id, creation_dispatcher) = setup();

    set_contract_address(not_star_owner);
    set_account_contract_address(not_star_owner);

    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_asteroid_cluster(coords, star_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid star id', 'ENTRYPOINT_FAILED'))]
fn test_create_asteroid_cluster_not_in_star() {
    let (_, star_owner, _, quasar_id, _, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_asteroid_cluster(coords, quasar_id);
}
