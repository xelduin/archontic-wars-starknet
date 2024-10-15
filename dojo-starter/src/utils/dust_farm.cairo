use dojo_starter::models::dust_emission::DustEmission;
use dojo_starter::models::dust_accretion::DustAccretion;
use dojo_starter::models::mass::Mass;

fn calculate_ARPS(at_ts: u64, pool_emission: DustEmission, pool_mass: Mass) -> u128 {
    assert(pool_mass.orbit_mass > 0, 'orbit mass is zero');
    let reward_per_share = pool_emission.emission_rate / pool_mass.orbit_mass.try_into().unwrap();
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
    pool_mass: Mass,
    star_accretion: DustAccretion,
    pool_emission: DustEmission
) -> u128 {
    let new_ARPS = calculate_ARPS(at_ts, pool_emission, pool_mass);
    
    let updated_pool_emission = DustEmission {
        entity: pool_emission.entity,
        emission_rate: pool_emission.emission_rate,
        ARPS: new_ARPS,
        last_update_ts: at_ts
    };

    let expected_dust_increase = calculate_unclaimed_dust(
        updated_pool_emission, star_accretion, star_mass
    );

    return expected_dust_increase;
}
