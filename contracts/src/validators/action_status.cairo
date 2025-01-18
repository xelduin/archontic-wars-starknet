use starknet::{ContractAddress};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::models::action_status::{ActionStatus, ActionType};

fn assert_is_idle(mut world: WorldStorage, entity_id: u32) {
    let action_status: ActionStatus = world.read_model(entity_id);

    assert(action_status.action_type == ActionType::Idle, 'not idle');
}

fn assert_is_in_battle(mut world: WorldStorage, entity_id: u32) {
    let action_status: ActionStatus = world.read_model(entity_id);

    assert(action_status.action_type == ActionType::Battle, 'not in bat');
}
