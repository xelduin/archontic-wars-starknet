use dojo_starter::models::dust_emission::DustEmission;
use dojo_starter::models::mass::Mass;

fn calculate_ARPS(at_ts: u64, pool_emission: DustEmission, pool_mass: Mass) -> u128 {
    let reward_per_share = pool_emission.emission_rate / pool_mass.orbit_mass.try_into().unwrap();
    let elapsed_ts = at_ts - pool_emission.last_update_ts;
    let ARPS_change = reward_per_share * elapsed_ts.try_into().unwrap();

    let updated_ARPS = pool_emission.ARPS + ARPS_change;

    return updated_ARPS;
}
