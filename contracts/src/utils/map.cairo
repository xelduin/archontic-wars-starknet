use starknet::get_block_timestamp;

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::utils::travel::get_ongoing_travel_position;

use astraplani::models::vec2::Vec2;
use astraplani::models::action_status::{ActionStatus, ActionType};

fn get_current_position(world: WorldStorage, entity_id: u32) -> Vec2 {
    let position: Position = world.read_model(entity_id);

    let action_status = get_action_type(world, entity_id);

    match action_status {
        ActionType::Travel => get_ongoing_travel_position(world, entity_id),
        _ => position.vec,
    }
}

fn calculate_distance(start: Vec2, destination: Vec2) -> u64 {
    let dx = destination.x - start.x;
    let dy = destination.y - start.y;
    (dx * dx + dy * dy).sqrt()
}

fn distance_between(world: WorldStorage, entity1: u32, entity2: u32) -> u64 {
    let pos1 = get_current_position(world, entity1);
    let pos2 = get_current_position(world, entity2);

    pos1.distance_to(pos2)
}

fn are_within_range(world: WorldStorage, entity1: u32, entity2: u32, range: u64) -> bool {
    distance_between(world, entity1, entity2) <= range
}
