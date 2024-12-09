use starknet::{
    ContractAddress,
    testing::{set_block_timestamp, set_contract_address, set_account_contract_address}
};
use starknet::contract_address_const;
use starknet::get_block_timestamp;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_star, spawners::spawn_asteroid_cluster,
    spawners::spawn_quasar
};
use astraplani::utils::testing::constants::{
    BASE_DUST_EMISSION_RATE, BASE_QUASAR_MASS, BASE_STAR_MASS
};
use astraplani::utils::travel_helpers::{get_arrival_ts, get_loosh_travel_cost};

use astraplani::models::owner::Owner;
use astraplani::models::mass::Mass;
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::travel_action::TravelAction;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::Position;
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::orbit::Orbit;

use astraplani::systems::movement::contracts::movement_systems::{
    movement_systems, IMovementSystemsDispatcher, IMovementSystemsDispatcherTrait
};


fn setup() -> (WorldStorage, u32, u32, Vec2, Vec2, ContractAddress, IMovementSystemsDispatcher) {
    let mut world = spawn_world();

    let (movement_address, _) = world.dns(@"movement_systems").unwrap();
    let movement_dispatcher = IMovementSystemsDispatcher { contract_address: movement_address };

    let sender_owner = contract_address_const::<'sender_owner'>();

    let quasar_vec = Vec2 { x: 1, y: 1 };
    let origin_vec = Vec2 { x: 20, y: 20 };
    let destination_vec = Vec2 { x: 42, y: 99 };

    let quasar_id = spawn_quasar(
        world, sender_owner, quasar_vec, BASE_QUASAR_MASS, BASE_DUST_EMISSION_RATE
    );

    let asteroid_cluster_mass = 100;
    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, sender_owner, origin_vec, quasar_id, asteroid_cluster_mass
    );

    let star_id = spawn_star(world, sender_owner, origin_vec, quasar_id, 1000);

    let orbit_center_body_type = CosmicBodyType::Quasar;
    let loosh_cost = get_loosh_travel_cost(
        world, origin_vec, destination_vec, orbit_center_body_type
    );

    let loosh_balance = LooshBalance { address: sender_owner, balance: loosh_cost * 10 };

    world.write_model_test(@loosh_balance);

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

    let travel_action: TravelAction = world.read_model(asteroid_cluster_id);

    assert(travel_action.target_position.is_equal(destination_vec), 'invalid target position');

    let cur_ts = get_block_timestamp();
    assert(travel_action.depart_ts == cur_ts, 'invalid departure ts');

    let asteroid_cluster_orbit: Orbit = world.read_model(asteroid_cluster_id);
    let orbit_center_body: CosmicBody = world.read_model(asteroid_cluster_orbit.orbit_center);
    let arrival_ts = get_arrival_ts(
        world, cur_ts, origin_vec, destination_vec, orbit_center_body.body_type
    );
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
#[should_panic(expected: ('body already travelling', 'ENTRYPOINT_FAILED'))]
fn test_begin_travel_while_travelling() {
    let (_, asteroid_cluster_id, _, _, destination_vec, sender_owner, movement_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.begin_travel(asteroid_cluster_id, destination_vec);
    movement_dispatcher.begin_travel(asteroid_cluster_id, Vec2 { x: 12, y: 12 });
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_begin_travel_insufficient_loosh() {
    let (mut world, asteroid_cluster_id, _, _, destination_vec, sender_owner, movement_dispatcher) =
        setup();

    let loosh_balance = LooshBalance { address: sender_owner, balance: 0 };

    world.write_model_test(@loosh_balance);

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    movement_dispatcher.begin_travel(asteroid_cluster_id, destination_vec);
}
