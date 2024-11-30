use dojo::world::IWorldDispatcher;

use astraplani::constants::{LOOSH_COST_CONFIG_ID, get_loosh_travel_cost_multiplier};
use astraplani::constants::{TRAVEL_SPEED_CONFIG_ID, get_travel_speed_multiplier};

use astraplani::models::config::LooshCostConfig;
use astraplani::models::config::TravelSpeedConfig;
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::cosmic_body::{CosmicBodyType};


fn get_arrival_ts(
    world: IWorldDispatcher,
    depart_ts: u64,
    origin_pos: Vec2,
    target_pos: Vec2,
    orbit_center_body_type: CosmicBodyType
) -> u64 {
    let base_travel_speed :  TravelSpeedConfig = world.read_model(TRAVEL_SPEED_CONFIG_ID)
        .base_travel_speed;

    let distance = origin_pos.chebyshev_distance(target_pos);
    let seconds_per_coordinate = get_travel_speed_multiplier(orbit_center_body_type)
        * base_travel_speed;

    let total_travel_time = seconds_per_coordinate * distance;
    let arrival_ts = depart_ts + total_travel_time;

    return arrival_ts;
}

fn get_loosh_travel_cost(
    world: IWorldDispatcher,
    origin_pos: Vec2,
    target_pos: Vec2,
    orbit_center_body_type: CosmicBodyType
) -> u128 {
    let distance = origin_pos.chebyshev_distance(target_pos);

    let base_travel_cost :  LooshCostConfig = world.read_model(LOOSH_COST_CONFIG_ID).base_travel_cost;
    let cost = get_loosh_travel_cost_multiplier(orbit_center_body_type) * base_travel_cost;

    return cost * distance.try_into().unwrap();
}
