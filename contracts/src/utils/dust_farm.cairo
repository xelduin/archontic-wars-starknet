use dojo::world::IWorldDispatcher;

use astraplani::constants::HARVEST_TIME_CONFIG_ID;
use astraplani::constants::DUST_VALUE_CONFIG_ID;

use astraplani::models::config::HarvestTimeConfig;
use astraplani::models::config::DustValueConfig;

use astraplani::models::dust_emission::DustEmission;
use astraplani::models::dust_accretion::DustAccretion;
use astraplani::models::mass::Mass;


fn calculate_ARPS(at_ts: u64, pool_emission: DustEmission, total_pool_mass: u64) -> u128 {
    assert(total_pool_mass > 0, 'orbit mass is zero');
    let reward_per_share = pool_emission.emission_rate / total_pool_mass.try_into().unwrap();
    let elapsed_ts = at_ts - pool_emission.last_update_ts;
    let ARPS_change = reward_per_share * elapsed_ts.try_into().unwrap();

    let updated_ARPS = pool_emission.ARPS + ARPS_change;

    return updated_ARPS;
}

fn calculate_unclaimed_dust(
    dust_emission: DustEmission, dust_accretion: DustAccretion, body_mass: Mass
) -> u128 {
    let updated_body_accretion = dust_emission.ARPS * body_mass.mass.try_into().unwrap();
    let unclaimed_dust = updated_body_accretion - dust_accretion.debt;

    return unclaimed_dust;
}

fn get_expected_dust_increase(
    at_ts: u64,
    star_mass: Mass,
    total_pool_mass: u64,
    star_accretion: DustAccretion,
    pool_emission: DustEmission
) -> u128 {
    let new_ARPS = calculate_ARPS(at_ts, pool_emission, total_pool_mass);

    let updated_pool_emission = DustEmission {
        entity: pool_emission.entity,
        emission_rate: pool_emission.emission_rate,
        ARPS: new_ARPS,
        last_update_ts: at_ts,
    };

    let expected_dust_increase = calculate_unclaimed_dust(
        updated_pool_emission, star_accretion, star_mass
    );

    return expected_dust_increase;
}

fn get_expected_claimable_dust_for_star(
    at_ts: u64,
    star_mass: Mass,
    total_pool_mass: u64,
    star_accretion: DustAccretion,
    pool_emission: DustEmission,
    star_sense: u8,
) -> u128 {
    let expected_dust_increase = get_expected_dust_increase(
        at_ts, star_mass, total_pool_mass, star_accretion, pool_emission
    );

    let claimable_dust_after_sense = expected_dust_increase * star_sense.try_into().unwrap() / 100;

    return claimable_dust_after_sense;
}

fn get_harvest_end_ts(
    world: IWorldDispatcher, start_ts: u64, harvest_amount: u128, mass: u64
) -> u64 {
    let mass_to_dust = get!(world, DUST_VALUE_CONFIG_ID, DustValueConfig).mass_to_dust;
    let dust_capacity = mass.try_into().unwrap() * mass_to_dust;

    assert(dust_capacity >= harvest_amount, 'cant harvest more than the mass');

    let harvest_time_config = get!(world, HARVEST_TIME_CONFIG_ID, HarvestTimeConfig);

    let min_time = harvest_time_config.min_harvest_time;
    let base_time = harvest_time_config.base_harvest_time;

    let harvest_time = base_time.try_into().unwrap() * harvest_amount / dust_capacity;

    let result: u64 = if harvest_time.try_into().unwrap() < min_time {
        start_ts + min_time
    } else {
        start_ts + harvest_time.try_into().unwrap()
    };

    return result;
}
