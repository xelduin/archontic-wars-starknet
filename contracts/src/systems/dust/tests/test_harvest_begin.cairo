use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_contract_address, set_account_contract_address, set_block_timestamp}
};
use starknet::contract_address_const;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::utils::dust_farm::{
    calculate_ARPS, get_expected_dust_increase, get_expected_claimable_dust_for_star,
    get_harvest_end_ts
};
use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_quasar, spawners::spawn_star,
    spawners::spawn_asteroid_cluster, dust_pool::add_to_dust_pool
};

use astraplani::models::owner::Owner;
use astraplani::models::mass::Mass;
use astraplani::models::vec2::Vec2;
use astraplani::models::dust_balance::DustBalance;
use astraplani::models::dust_accretion::DustAccretion;
use astraplani::models::dust_emission::DustEmission;
use astraplani::models::dust_pool::DustPool;
use astraplani::models::orbit::Orbit;
use astraplani::models::basal_attributes::{
    BasalAttributes, BasalAttributesType, BasalAttributesImpl
};
use astraplani::models::dust_cloud::DustCloud;
use astraplani::models::harvest_action::HarvestAction;
use astraplani::models::travel_action::TravelAction;
use astraplani::models::position::Position;
use astraplani::constants::DUST_VALUE_CONFIG_ID;
use astraplani::models::config::DustValueConfig;

use astraplani::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

// Mock setup for the test
fn setup() -> (WorldStorage, u32, u32, ContractAddress, ContractAddress, IDustSystemsDispatcher) {
    let mut world = spawn_world();

    let (dust_address, _) = world.dns(@"dust_systems").unwrap();
    let dust_dispatcher = IDustSystemsDispatcher { contract_address: dust_address };

    // Accounts
    let sender_owner = contract_address_const::<'sender_owner'>();
    let non_owner = contract_address_const::<'non_owner'>();

    let dust_decimals = 1_000_000_000_000_000_000;
    // SET UP DUST POOL
    let coords = Vec2 { x: 100, y: 100 };
    let emission_rate = 1_000_000_000_000_000; // 0.001 dust per second
    let quasar_mass = 5_000_000;
    let quasar_id = spawn_quasar(world, sender_owner, coords, emission_rate, quasar_mass);

    let star_id = spawn_star(world, sender_owner, coords, quasar_id, 1_000_000);
    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, sender_owner, coords, quasar_id, 10_000
    );

    let asteroid_orbit = Orbit { entity_id: asteroid_cluster_id, orbit_center: quasar_id };
    let star_orbit = Orbit { entity_id: star_id, orbit_center: quasar_id };
    let dust_cloud = DustCloud {
        x: coords.x, y: coords.y, orbit_center: quasar_id, dust_balance: dust_decimals * 1_000_000
    };

    world.write_model_test(@asteroid_orbit);
    world.write_model_test(@star_orbit);
    world.write_model_test(@dust_cloud);

    (world, asteroid_cluster_id, quasar_id, sender_owner, non_owner, dust_dispatcher)
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

    let asteroid_cluster_mass: Mass = world.read_model(asteroid_cluster_id);
    let end_ts = get_harvest_end_ts(world, cur_ts, harvest_amount, asteroid_cluster_mass.mass);

    let harvest_action: HarvestAction = world.read_model(asteroid_cluster_id);

    assert(harvest_action.start_ts == cur_ts, 'start_ts is wrong');
    assert(harvest_action.end_ts == end_ts, 'end_ts is wrong');
    assert(harvest_action.harvest_amount == harvest_amount, 'harvest amount wrong');
}


#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not enough dust', 'ENTRYPOINT_FAILED'))]
fn test_harvest_begin_no_dust() {
    let (mut world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    // We move to 20,20, where there isnt a DustCloud
    let new_asteroid_pos = Position { entity_id: asteroid_cluster_id, vec: Vec2 { x: 20, y: 20 } };

    world.write_model_test(@new_asteroid_pos);

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
    let (world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let asteroid_cluster_mass: Mass = world.read_model(asteroid_cluster_id);
    let dust_value_config: DustValueConfig = world.read_model(DUST_VALUE_CONFIG_ID);

    let harvest_capacity: u128 = asteroid_cluster_mass.mass.try_into().unwrap()
        * dust_value_config.mass_to_dust;

    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_capacity + 1);
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
    let (mut world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    let cur_ts = get_block_timestamp();
    let travel_action = TravelAction {
        entity_id: asteroid_cluster_id,
        depart_ts: cur_ts,
        arrival_ts: cur_ts + 10_000,
        target_position: Vec2 { x: 20, y: 20 }
    };

    world.write_model_test(@travel_action);

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

