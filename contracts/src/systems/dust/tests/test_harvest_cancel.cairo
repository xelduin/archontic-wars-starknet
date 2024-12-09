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

use astraplani::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

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

    let asteroid_orbit = Orbit { entity: asteroid_cluster_id, orbit_center: quasar_id };
    let star_orbit = Orbit { entity: star_id, orbit_center: quasar_id };
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
fn test_harvest_cancel_valid() {
    let (world, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_dust_balance = get!(world, asteroid_cluster_id, DustBalance);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);

    dust_dispatcher.cancel_dust_harvest(asteroid_cluster_id);

    let new_dust_balance = get!(world, asteroid_cluster_id, DustBalance);
    assert(new_dust_balance.balance == old_dust_balance.balance, 'dust balance incorrect');

    let harvest_action = get!(world, asteroid_cluster_id, HarvestAction);
    assert(harvest_action.end_ts == 0, 'harvest action not destroyed');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not harvesting', 'ENTRYPOINT_FAILED'))]
fn test_harvest_cancel_not_harvesting() {
    let (_, asteroid_cluster_id, _, sender_owner, _, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    dust_dispatcher.cancel_dust_harvest(asteroid_cluster_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not owner', 'ENTRYPOINT_FAILED'))]
fn test_harvest_cancel_not_owner() {
    let (_, asteroid_cluster_id, _, sender_owner, non_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let harvest_amount = 1_000;
    dust_dispatcher.begin_dust_harvest(asteroid_cluster_id, harvest_amount);

    set_contract_address(non_owner);
    set_account_contract_address(non_owner);

    dust_dispatcher.cancel_dust_harvest(asteroid_cluster_id);
}

