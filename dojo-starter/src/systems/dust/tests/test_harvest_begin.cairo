use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::Vec2;
use dojo_starter::models::dust_balance::DustBalance;
use dojo_starter::models::dust_accretion::DustAccretion;
use dojo_starter::models::dust_emission::DustEmission;
use dojo_starter::models::dust_pool::DustPool;
use dojo_starter::models::orbit::Orbit;
use dojo_starter::models::basal_attributes::{
    BasalAttributes, BasalAttributesType, BasalAttributesImpl
};
use dojo_starter::models::dust_cloud::DustCloud;
use dojo_starter::models::harvest_action::HarvestAction;
use dojo_starter::models::travel_action::TravelAction;
use dojo_starter::models::position::Position;

use dojo_starter::utils::dust_farm::{
    calculate_ARPS, get_expected_dust_increase, get_expected_claimable_dust_for_star,
    get_harvest_end_ts
};

use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_contract_address, set_account_contract_address, set_block_timestamp}
};
use starknet::contract_address_const;

use dojo_starter::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

use dojo_starter::utils::testing::{
    world::spawn_world, spawners::spawn_galaxy, spawners::spawn_star,
    spawners::spawn_asteroid_cluster, dust_pool::add_to_dust_pool
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (
    IWorldDispatcher, u32, u32, ContractAddress, ContractAddress, IDustSystemsDispatcher
) {
    let world = spawn_world();

    let dust_address = world
        .deploy_contract('salt', dust_systems::TEST_CLASS_HASH.try_into().unwrap());
    let dust_dispatcher = IDustSystemsDispatcher { contract_address: dust_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), dust_address);

    // Accounts
    let sender_owner = contract_address_const::<'sender_owner'>();
    let non_owner = contract_address_const::<'non_owner'>();

    let dust_decimals = 1_000_000_000_000_000_000;
    // SET UP DUST POOL
    let coords = Vec2 { x: 100, y: 100 };
    let emission_rate = 1_000_000_000_000_000; // 0.001 dust per second
    let galaxy_mass = 5_000_000;
    let galaxy_id = spawn_galaxy(world, sender_owner, coords, emission_rate, galaxy_mass);

    let star_id = spawn_star(world, sender_owner, coords, 1_000_000);
    let asteroid_cluster_id = spawn_asteroid_cluster(world, sender_owner, coords, 10_000);

    set!(
        world,
        (
            Orbit { entity: asteroid_cluster_id, orbit_center: galaxy_id },
            Orbit { entity: star_id, orbit_center: galaxy_id },
            DustCloud {
                x: coords.x,
                y: coords.y,
                orbit_center: galaxy_id,
                dust_balance: dust_decimals * 1_000_000
            }
        ),
    );

    (world, asteroid_cluster_id, galaxy_id, sender_owner, non_owner, dust_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_harvest_begin_valid() {
    let (world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let cur_ts = get_block_timestamp();

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);

    let asteroid_cluster_mass = get!(world, asteroid_cluster_id, Mass);
    let end_ts = get_harvest_end_ts(world, cur_ts, harvest_amount, asteroid_cluster_mass.mass);

    let harvest_action = get!(world, asteroid_cluster_id, HarvestAction);

    assert(harvest_action.start_ts == cur_ts, 'start_ts is wrong');
    assert(harvest_action.end_ts == end_ts, 'end_ts is wrong');
    assert(harvest_action.harvest_amount == harvest_amount, 'harvest amount wrong');
}


#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not enough dust', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_no_dust() {
    let (world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    // We move to 20,20, where there isnt a DustCloud
    set!(world, (Position { entity: asteroid_cluster_id, vec: Vec2 { x: 20, y: 20 } }));

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not owner', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_not_owner() {
    let (_, asteroid_cluster_id, _, _, non_owner, dust_dispatcher) = setup();

    set_contract_address(non_owner);
    set_account_contract_address(non_owner);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('harvest amount too high', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_insufficient_mass() {
    let (_, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let harvest_amount = 1_000_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('entity already harvesting', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_already_harvesting() {
    let (_, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('cannot harvest while travelling', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_is_travelling() {
    let (world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    let cur_ts = get_block_timestamp();
    set!(
        world,
        (TravelAction {
            entity: asteroid_cluster_id,
            depart_ts: cur_ts,
            arrival_ts: cur_ts + 10_000,
            target_position: Vec2 { x: 20, y: 20 }
        })
    );

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid body type', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_invalid_body() {
    let (_, _, star_id, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(star_id, harvest_amount);
}

