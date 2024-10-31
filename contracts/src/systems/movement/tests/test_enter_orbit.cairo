use astraplani::models::owner::Owner;
use astraplani::models::mass::Mass;
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::travel_action::TravelAction;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::Position;
use astraplani::models::orbit::Orbit;

use astraplani::utils::travel_helpers::{get_arrival_ts, get_loosh_travel_cost};

use starknet::{
    ContractAddress,
    testing::{set_block_timestamp, set_contract_address, set_account_contract_address}
};
use starknet::contract_address_const;
use starknet::get_block_timestamp;

use astraplani::systems::movement::contracts::movement_systems::{
    movement_systems, IMovementSystemsDispatcher, IMovementSystemsDispatcherTrait
};


use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_star, spawners::spawn_asteroid_cluster
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};


// Mock setup for the test
fn setup() -> (IWorldDispatcher, u32, u32, u32, u32, ContractAddress, IMovementSystemsDispatcher) {
    let world = spawn_world();

    let movement_address = world
        .deploy_contract('movement_systems', movement_systems::TEST_CLASS_HASH.try_into().unwrap());
    let movement_dispatcher = IMovementSystemsDispatcher { contract_address: movement_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), movement_address);

    //println!("{}", movement_address);

    let sender_owner = contract_address_const::<'sender_owner'>();

    let origin_vec = Vec2 { x: 20, y: 20 };
    let non_proximal_vec = Vec2 { x: 42, y: 99 };

    let asteroid_cluster_mass = 100;

    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, sender_owner, origin_vec, asteroid_cluster_mass
    );
    let proximal_asteroid_cluster_id = spawn_asteroid_cluster(
        world, sender_owner, origin_vec, asteroid_cluster_mass
    );

    let proximal_star_id = spawn_star(world, sender_owner, origin_vec, 1000);
    let non_proximal_star_id = spawn_star(world, sender_owner, non_proximal_vec, 1000);

    (
        world,
        asteroid_cluster_id,
        proximal_asteroid_cluster_id,
        proximal_star_id,
        non_proximal_star_id,
        sender_owner,
        movement_dispatcher
    )
}


#[test]
#[available_gas(3000000000000)]
fn test_enter_orbit_valid() {
    let (world, asteroid_cluster_id, _, proximal_star_id, _, sender_owner, movement_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.enter_orbit(asteroid_cluster_id, proximal_star_id);

    let asteroid_cluster_orbit = get!(world, asteroid_cluster_id, Orbit);
    assert(asteroid_cluster_orbit.orbit_center == proximal_star_id, 'failed to set orbit');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in proximity', 'ENTRYPOINT_FAILED'))]
fn test_enter_orbit_not_proximal() {
    let (_, asteroid_cluster_id, _, _, non_proximal_star_id, sender_owner, movement_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.enter_orbit(asteroid_cluster_id, non_proximal_star_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('cannot orbit body type', 'ENTRYPOINT_FAILED'))]
fn test_enter_orbit_non_star() {
    let (
        _,
        asteroid_cluster_id,
        proximal_asteroid_cluster_id,
        _,
        _,
        sender_owner,
        movement_dispatcher
    ) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.enter_orbit(asteroid_cluster_id, proximal_asteroid_cluster_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('body type cannot enter orbit', 'ENTRYPOINT_FAILED'))]
fn test_enter_orbit_as_non_asteroid() {
    let (_, asteroid_cluster_id, _, proximal_star_id, _, sender_owner, movement_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.enter_orbit(proximal_star_id, asteroid_cluster_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('body is travelling', 'ENTRYPOINT_FAILED'))]
fn test_enter_orbit_while_travelling() {
    let (world, asteroid_cluster_id, _, proximal_star_id, _, sender_owner, movement_dispatcher) =
        setup();

    let cur_ts = get_block_timestamp();
    set!(
        world,
        (TravelAction {
            entity: asteroid_cluster_id,
            depart_ts: cur_ts,
            arrival_ts: cur_ts + 1000,
            target_position: Vec2 { x: 22, y: 22 }
        })
    );

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.enter_orbit(asteroid_cluster_id, proximal_star_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in proximity', 'ENTRYPOINT_FAILED'))]
fn test_enter_orbit_already_in_orbit() {
    let (world, asteroid_cluster_id, _, proximal_star_id, _, sender_owner, movement_dispatcher) =
        setup();

    set!(world, ((Orbit { entity: asteroid_cluster_id, orbit_center: proximal_star_id })));

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.enter_orbit(asteroid_cluster_id, proximal_star_id);
}
