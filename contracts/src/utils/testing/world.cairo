use core::array::{ArrayTrait, SpanTrait};
use astraplani::models::{
    loosh_balance, basal_attributes, incubation, owner, position, mass, travel_action, vec2,
    dust_balance, dust_emission, dust_accretion, dust_cloud, orbit, loosh_sink, cosmic_body,
    dust_pool, orbital_mass, harvest_action, config
};
use dojo::utils::test::{spawn_test_world};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use starknet::{ContractAddress, contract_address_const};

fn spawn_world() -> IWorldDispatcher {
    let mut models = array![
        loosh_balance::loosh_balance::TEST_CLASS_HASH,
        basal_attributes::basal_attributes::TEST_CLASS_HASH,
        incubation::incubation::TEST_CLASS_HASH,
        owner::owner::TEST_CLASS_HASH,
        position::position::TEST_CLASS_HASH,
        position::orbit_center_at_position::TEST_CLASS_HASH,
        mass::mass::TEST_CLASS_HASH,
        orbital_mass::orbital_mass::TEST_CLASS_HASH,
        travel_action::travel_action::TEST_CLASS_HASH,
        dust_balance::dust_balance::TEST_CLASS_HASH,
        dust_emission::dust_emission::TEST_CLASS_HASH,
        dust_accretion::dust_accretion::TEST_CLASS_HASH,
        dust_pool::dust_pool::TEST_CLASS_HASH,
        dust_cloud::dust_cloud::TEST_CLASS_HASH,
        orbit::orbit::TEST_CLASS_HASH,
        cosmic_body::cosmic_body::TEST_CLASS_HASH,
        harvest_action::harvest_action::TEST_CLASS_HASH,
        //CONFIGS
        config::admin_config::TEST_CLASS_HASH,
        config::dust_value_config::TEST_CLASS_HASH,
        config::dust_emission_config::TEST_CLASS_HASH,
        config::harvest_time_config::TEST_CLASS_HASH,
        config::base_cosmic_body_mass_config::TEST_CLASS_HASH,
        config::min_orbit_center_mass_config::TEST_CLASS_HASH,
        config::max_cosmic_body_mass_config::TEST_CLASS_HASH,
        config::loosh_cost_config::TEST_CLASS_HASH,
        config::travel_speed_config::TEST_CLASS_HASH,
    ];

    let world = spawn_test_world(["astraplani"].span(), models.span());

    world.uuid();

    setup_config(world);

    return world;
}

use astraplani::constants::{
    ADMIN_CONFIG_ID, DUST_VALUE_CONFIG_ID, DUST_EMISSION_CONFIG_ID, LOOSH_COST_CONFIG_ID,
    HARVEST_TIME_CONFIG_ID, COSMIC_BODY_MASS_CONFIG_ID, TRAVEL_SPEED_CONFIG_ID
};

const DUST_TO_MASS_CONVERSION: u128 = 1;
const BASE_DUST_EMISSION_RATE: u128 = 1 * 1_000_000_000_000_000_000;

const BASE_STAR_MASS: u64 = 1_000_000;
const BASE_QUASAR_MASS: u64 = 1_000_000_000;
const MAX_ASTEROID_CLUSTER_MASS: u64 = 100_000;

const BASE_LOOSH_TRAVEL_COST: u128 = 5;
const BASE_LOOSH_CREATION_COST: u128 = 10;

const BASE_TRAVEL_SECONDS_PER_TILE: u64 = 60;

const MIN_HARVEST_SECONDS: u64 = 60 * 60;
const BASE_HARVEST_SECONDS: u64 = 60 * 60 * 24;


fn setup_config(world: IWorldDispatcher) {
    set!(
        world,
        (
            // DUST CONFIGS
            config::DustValueConfig {
                config_id: DUST_VALUE_CONFIG_ID, dust_to_mass: DUST_TO_MASS_CONVERSION
            },
            config::DustEmissionConfig {
                config_id: DUST_EMISSION_CONFIG_ID, base_dust_emission: BASE_DUST_EMISSION_RATE
            },
            // MASS CONFIGS
            config::BaseCosmicBodyMassConfig {
                config_id: COSMIC_BODY_MASS_CONFIG_ID,
                base_star_mass: BASE_STAR_MASS,
                base_quasar_mass: BASE_QUASAR_MASS
            },
            config::MaxCosmicBodyMassConfig {
                config_id: COSMIC_BODY_MASS_CONFIG_ID,
                max_asteroid_cluster_mass: MAX_ASTEROID_CLUSTER_MASS
            }, //This needs to be joined with bsae_cosmic_body_config
            config::LooshCostConfig {
                config_id: LOOSH_COST_CONFIG_ID,
                base_travel_cost: BASE_LOOSH_TRAVEL_COST,
                base_creation_cost: BASE_LOOSH_CREATION_COST
            },
            config::TravelSpeedConfig {
                config_id: TRAVEL_SPEED_CONFIG_ID, base_travel_speed: BASE_TRAVEL_SECONDS_PER_TILE
            },
            //config::AdminConfig { config_id: ADMIN_CONFIG_ID, admin_address:},
            config::HarvestTimeConfig {
                config_id: HARVEST_TIME_CONFIG_ID,
                min_harvest_time: MIN_HARVEST_SECONDS,
                base_harvest_time: BASE_HARVEST_SECONDS,
            },
        )
    );
}
