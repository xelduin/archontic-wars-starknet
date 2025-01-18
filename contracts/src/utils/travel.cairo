use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::utils::action::get_action_progress;

use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::position::Position;
use astraplani::models::config::PneumaCostsConfig;
use astraplani::models::action_status::{ActionStatus, TravelAction, ActionType};

use astraplani::constants::PNEUMA_COSTS_CONFIG_ID;

fn get_travel_action(world: WorldStorage, entity_id: u32) -> Option<TravelAction> {
    let action_status: ActionStatus = world.read_model(entity_id);

    if action_status.action_type != ActionType::Travel {
        return Option::None;
    }

    let travel_action: TravelAction = world.read_model(entity_id);
    Option::Some(travel_action)
}

fn get_travel_duration(world: WorldStorage, entity_id: u32, params: TravelParams) -> u64 {
    const BASE_SPEED: u64 = 100;
    const TIME_FACTOR: u64 = 100;

    let distance = calculate_distance(start_position, end_position);
    let speed_modifier = get_soul_speed_modifier(world, entity_id);
    let speed = BASE_SPEED * speed_modifier / 100;

    (distance * TIME_FACTOR) / speed
}

fn get_ongoing_travel_position(travel_action: TravelAction) -> Vec2 {
    let current_time = get_block_timestamp();

    if current_time <= travel_action.start_timestamp {
        return travel_action.start_position;
    }

    if current_time >= travel_action.end_timestamp {
        return travel_action.end_position;
    }

    interpolate_travel_position(current_time, travel_action)
}

fn interpolate_travel_position(current_time: u64, travel_action: TravelAction) -> Vec2 {
    let (elapsed, total_duration) = get_action_progress(
        current_time, travel_action.start_timestamp, travel_action.end_timestamp
    );

    if elsapsed == total_duration {
        return travel_action.end_position;
    };         

    return Vec2 {
        x: travel_action.start_position.x
            + ((travel_action.end_position.x - travel_action.start_position.x)
                * elapsed
                / total_duration),
        y: travel_action.start_position.y
            + ((travel_action.end_position.y - travel_action.start_position.y)
                * elapsed
                / total_duration)
    }
}

fn get_pneuma_travel_cost(world: WorldStorage, origin_coords: Vec2, target_coords: Vec2) -> u128 {
    let pneuma_costs_config: PneumaCostsConfig = world.read_model(PNEUMA_COSTS_CONFIG_ID);

    let distance = origin_coords.distance_to(target_coords);

    let final_cost = distance.unwrap().into() * pneuma_costs_config.cost_per_unit;

    return final_cost;
}

fn get_soul_speed_modifier(world: WorldStorage, entity_id: u32) -> u64 {
    // Temporary default modifier (no boost)
    100
}
