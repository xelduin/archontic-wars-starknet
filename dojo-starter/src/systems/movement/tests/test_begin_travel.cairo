use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::{Vec2, Vec2Impl};
use dojo_starter::models::travel_action::TravelAction;
use dojo_starter::models::loosh_balance::LooshBalance;
use dojo_starter::models::position::Position;

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
fn setup() -> (
    IWorldDispatcher, u32, u32, Vec2, Vec2, ContractAddress, IMovementSystemsDispatcher
) {
    let world = spawn_world();

    let movement_address = world
        .deploy_contract('movement_systems', movement_systems::TEST_CLASS_HASH.try_into().unwrap());
    let movement_dispatcher = IMovementSystemsDispatcher { contract_address: movement_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), movement_address);

    //println!("{}", movement_address);

    let sender_owner = contract_address_const::<'sender_owner'>();

    let origin_vec = Vec2 { x: 20, y: 20 };
    let destination_vec = Vec2 { x: 42, y: 99 };

    let asteroid_cluster_mass = 100;

    let loosh_cost = get_loosh_travel_cost(origin_vec, destination_vec);
    set!(world, (LooshBalance { address: sender_owner, balance: loosh_cost }));

    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, sender_owner, origin_vec, asteroid_cluster_mass
    );

    let star_id = spawn_star(world, sender_owner, origin_vec, 1000);

    (
        world,
        asteroid_cluster_id,
        star_id,
        origin_vec,
        destination_vec,
        sender_owner,
        movement_dispatcher
    )
}

fn get_arrival_ts(depart_ts: u64, origin_pos: Vec2, target_pos: Vec2) -> u64 {
    let distance = origin_pos.chebyshev_distance(target_pos);
    let seconds_per_coordinate = 60 * 15;
    let total_travel_time = seconds_per_coordinate * distance;
    let arrival_ts = depart_ts + total_travel_time;

    return arrival_ts;
}

fn get_loosh_travel_cost(origin_pos: Vec2, target_pos: Vec2) -> u128 {
    let distance = origin_pos.chebyshev_distance(target_pos);

    let cost = distance.try_into().unwrap() * 5_u128;

    return cost;
}

#[test]
#[available_gas(3000000000000)]
fn test_begin_travel_valid() {
    let (
        world,
        asteroid_cluster_id,
        _,
        origin_vec,
        destination_vec,
        sender_owner,
        movement_dispatcher
    ) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.begin_travel(asteroid_cluster_id, destination_vec);

    let travel_action = get!(world, asteroid_cluster_id, TravelAction);

    assert(travel_action.target_position.is_equal(destination_vec), 'invalid target position');

    let cur_ts = get_block_timestamp();
    assert(travel_action.depart_ts == cur_ts, 'invalid departure ts');

    let arrival_ts = get_arrival_ts(cur_ts, origin_vec, destination_vec);
    assert(travel_action.arrival_ts == arrival_ts, 'invalid arrival ts');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('already at target pos', 'ENTRYPOINT_FAILED'))]
fn test_begin_travel_same_pos() {
    let (_, asteroid_cluster_id, _, origin_vec, _, sender_owner, movement_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.begin_travel(asteroid_cluster_id, origin_vec);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('body type cant travel', 'ENTRYPOINT_FAILED'))]
fn test_begin_travel_non_cluster() {
    let (_, _, star_id, _, destination_vec, sender_owner, movement_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.begin_travel(star_id, destination_vec);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_begin_travel_insufficient_loosh() {
    let (world, asteroid_cluster_id, _, _, destination_vec, sender_owner, movement_dispatcher) =
        setup();

    set!(world, (LooshBalance { address: sender_owner, balance: 0 }));

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.begin_travel(asteroid_cluster_id, destination_vec);
}
