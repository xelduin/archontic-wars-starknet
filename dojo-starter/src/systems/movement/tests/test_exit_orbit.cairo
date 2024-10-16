use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::{Vec2, Vec2Impl};
use dojo_starter::models::travel_action::TravelAction;
use dojo_starter::models::loosh_balance::LooshBalance;
use dojo_starter::models::position::Position;
use dojo_starter::models::orbit::Orbit;

use dojo_starter::utils::travel_helpers::{get_arrival_ts, get_loosh_travel_cost};

use starknet::{
    ContractAddress,
    testing::{set_block_timestamp, set_contract_address, set_account_contract_address}
};
use starknet::contract_address_const;
use starknet::get_block_timestamp;

use dojo_starter::systems::movement::contracts::movement_systems::{
    movement_systems, IMovementSystemsDispatcher, IMovementSystemsDispatcherTrait
};


use dojo_starter::utils::testing::{
    world::spawn_world, spawners::spawn_star, spawners::spawn_asteroid_cluster
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};


// Mock setup for the test
fn setup() -> (IWorldDispatcher, u32, ContractAddress, IMovementSystemsDispatcher) {
    let world = spawn_world();

    let movement_address = world
        .deploy_contract('movement_systems', movement_systems::TEST_CLASS_HASH.try_into().unwrap());
    let movement_dispatcher = IMovementSystemsDispatcher { contract_address: movement_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), movement_address);

    //println!("{}", movement_address);

    let sender_owner = contract_address_const::<'sender_owner'>();

    let origin_vec = Vec2 { x: 20, y: 20 };

    let asteroid_cluster_mass = 100;

    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, sender_owner, origin_vec, asteroid_cluster_mass
    );
    let star_id = spawn_star(world, sender_owner, origin_vec, 1000);

    set!(world, (Orbit { entity: asteroid_cluster_id, orbit_center: star_id }));

    (world, asteroid_cluster_id, sender_owner, movement_dispatcher)
}


#[test]
#[available_gas(3000000000000)]
fn test_exit_orbit_valid() {
    let (world, asteroid_cluster_id, sender_owner, movement_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.exit_orbit(asteroid_cluster_id);

    let asteroid_cluster_orbit = get!(world, asteroid_cluster_id, Orbit);
    assert(asteroid_cluster_orbit.orbit_center == 0, 'failed to delete orbit');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in an orbit', 'ENTRYPOINT_FAILED'))]
fn test_exit_orbit_not_in_orbit() {
    let (world, asteroid_cluster_id, sender_owner, movement_dispatcher) = setup();

    set!(world, (Orbit { entity: asteroid_cluster_id, orbit_center: 0 }));

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.exit_orbit(asteroid_cluster_id);
}
