use dojo_starter::models::vec2::{Vec2, Vec2Impl};
use dojo_starter::models::cosmic_body::{CosmicBodyType};

fn get_seconds_per_tile_speed(orbit_center_body_type: CosmicBodyType) -> u64 {
    match orbit_center_body_type {
        CosmicBodyType::Star => 60, // 1 minutes per tile
        CosmicBodyType::Galaxy => 60 * 60, // 1 hour per tile
        _ => 60 * 60 * 24 // 1 day per tile
    }
}

fn get_arrival_ts(
    depart_ts: u64, origin_pos: Vec2, target_pos: Vec2, orbit_center_body_type: CosmicBodyType
) -> u64 {
    let distance = origin_pos.chebyshev_distance(target_pos);
    let seconds_per_coordinate = get_seconds_per_tile_speed(orbit_center_body_type);
    let total_travel_time = seconds_per_coordinate * distance;
    let arrival_ts = depart_ts + total_travel_time;

    return arrival_ts;
}

fn get_loosh_travel_cost(
    origin_pos: Vec2, target_pos: Vec2, orbit_center_body_type: CosmicBodyType
) -> u128 {
    let distance = origin_pos.chebyshev_distance(target_pos);

    let cost = distance.try_into().unwrap() * 5_u128;

    match orbit_center_body_type {
        CosmicBodyType::Star => cost,
        CosmicBodyType::Galaxy => cost * 100,
        _ => cost * 10_000
    }
}
