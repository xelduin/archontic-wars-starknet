use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::action_status::{ActionStatus, ActionType};

fn get_action_progress(current: u64, start: u64, end: u64) -> (u64, u64) {
    assert(current >= start, 'invalid timestamps');

    let elapsed = current - start;
    let total_duration = end - start;

    return (elapsed, total_duration);
}

fn get_action_type(world: WorldStorage, entity_id: u32) -> ActionType {
    let action_status: ActionStatus = world.read_model(entity_id);

    return action_status.action_type;
}
