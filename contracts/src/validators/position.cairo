use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::position::Position;

fn assert_entities_at_same_coords(mut world: WorldStorage, entity_id: u32, target_id: u32) {
    let entity_id: Position = world.read_model(entity_id);
    let target_id: Position = world.read_model(target_id);

    assert(entity_id.vec.is_equal(target_id.vec), 'not at same coords');
}

fn assert_not_at_coords(mut world: WorldStorage, entity_id: u32, target_coords: Vec2) {
    let entity_id: Position = world.read_model(entity_id);

    assert(entity_id.vec.is_equal(target_coords) == false, 'at coords');
}
