use dojo_starter::models::vec2::{Vec2, Vec2Impl};

fn get_arrival_ts(depart_ts: u64, origin_pos: Vec2, target_pos: Vec2) -> u64 {
    let distance = origin_pos.chebyshev_distance(target_pos);
    let seconds_per_coordinate = 60 * 15;
    let total_travel_time = seconds_per_coordinate * distance;
    let arrival_ts = depart_ts + total_travel_time;

    return arrival_ts;
}

fn get_loosh_travel_cost(origin_pos: Vec2, target_pos: Vec2) -> u128 {
    let distance = origin_pos.chebyshev_distance(target_pos);

    let cost = distance.try_into().unwrap() * 5_u128;

    return cost;
}
