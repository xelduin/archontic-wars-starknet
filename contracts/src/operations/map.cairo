use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::action_status::ActionStatus;
use astraplani::models::vec2::Vec2;
use astraplani::models::position::Position;

fn set_position(world: WorldStorage, entity_id: u32, pos: Vec2) {
    let new_position = Position { vec: pos };
    world.write_model(entity_id, new_position);
}
