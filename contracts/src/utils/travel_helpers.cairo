use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::constants::{LOOSH_COST_CONFIG_ID, get_loosh_travel_cost_multiplier};
use astraplani::constants::{TRAVEL_SPEED_CONFIG_ID, get_travel_speed_multiplier};

use astraplani::models::config::LooshCostConfig;
use astraplani::models::config::TravelSpeedConfig;
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::cosmic_body::{CosmicBodyType};


fn get_arrival_ts(
    mut world: WorldStorage,
    depart_ts: u64,
    origin_pos: Vec2,
    target_pos: Vec2,
    orbit_center_body_type: CosmicBodyType
) -> u64 {
    let travel_speed_config : TravelSpeedConfig = world.read_model(TRAVEL_SPEED_CONFIG_ID);

    let distance = origin_pos.chebyshev_distance(target_pos);
    let seconds_per_coordinate = get_travel_speed_multiplier(orbit_center_body_type)
        * travel_speed_config.base_travel_speed;

    let total_travel_time = seconds_per_coordinate * distance;
    let arrival_ts = depart_ts + total_travel_time;

    return arrival_ts;
}

fn get_loosh_travel_cost(
    mut world: WorldStorage,
    origin_pos: Vec2,
    target_pos: Vec2,
    orbit_center_body_type: CosmicBodyType
) -> u128 {
    let distance = origin_pos.chebyshev_distance(target_pos);

    let loosh_cost_config : LooshCostConfig = world.read_model(LOOSH_COST_CONFIG_ID);
    let cost = get_loosh_travel_cost_multiplier(orbit_center_body_type) * loosh_cost_config.base_travel_cost;

    return cost * distance.try_into().unwrap();
}
