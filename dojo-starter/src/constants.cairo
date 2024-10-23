use starknet::{ContractAddress, contract_address_try_from_felt252};
use dojo_starter::models::cosmic_body::CosmicBodyType;

const ADMIN_CONFIG_ID: u32 = 0;
const DUST_RESOURCE_CONFIG_ID: u32 = 0;
const DUST_EMISSION_CONFIG_ID: u32 = 0;
const LOOSH_TRAVEL_COST_CONFIG_ID: u32 = 0;
const LOOSH_CREATION_COST_CONFIG_ID: u32 = 0;

const DUST_TO_MASS: u64 = 1;
const MIN_ORBIT_CENTER_MASS_MULTIPLIER: u8 = 10;
const BASE_DUST_EMISSION: u128 = 1_000_000_000_000;

const MIN_HARVEST_TIME: u64 = 60 * 60;
const BASE_HARVEST_TIME: u64 = 60 * 60 * 24;

const MAX_ASTEROID_CLUSTER_MASS: u128 = 100_000;
const BASE_GALAXY_MASS: u128 = 1_000_000_000;
const BASE_STAR_MASS: u128 = 1_000_000;

fn get_star_mass_ranges() -> Span<(u8, (u128, u128))> {
    return array![
        (1, (1, 2)), // Level 1
        (2, (2, 4)), // Level 2
        (3, (4, 8)), // Level 3
        (4, (8, 16)), // Level 4
        (5, (16, 32)), // Level 5
        (6, (32, 64)), // Level 6
        (7, (64, 128)), // Level 7
        (8, (128, 256)), // Level 8
        (9, (256, 512)), // Level 9
        (10, (512, 1000)), // Level 10
    ]
        .span();
}

const BASE_LOOSH_TRAVEL_COST: u128 = 5;
fn get_travel_speed_multiplier() -> Span<(CosmicBodyType, u128)> {
    return array![
        (CosmicBodyType::Star, 1), (CosmicBodyType::Galaxy, 60), (CosmicBodyType::None, 60 * 24),
    ]
        .span();
}

const BASE_TRAVEL_SPEED_PER_TILE: u64 = 60;
fn get_loosh_travel_cost_multiplier() -> Span<(CosmicBodyType, u128)> {
    return array![
        (CosmicBodyType::Star, 1), // Level 1
        (CosmicBodyType::Galaxy, 100), // Level 2
        (CosmicBodyType::None, 10_000), // Level 3
    ]
        .span();
}


const BASE_LOOSH_CREATION_COST: u128 = 10;
fn get_loosh_creation_cost_multiplier() -> Span<(CosmicBodyType, u128)> {
    return array![
        (CosmicBodyType::Protostar, 20), // Level 1
         (CosmicBodyType::AsteroidCluster, 2), // Level 2
    ]
        .span();
}
