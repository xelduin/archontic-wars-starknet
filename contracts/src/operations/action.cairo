use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::operations;

use astraplani::utils::action::get_action_typee;

use astraplani::models::action::{ActionType, ActionParams, ActionStatus};
use astraplani::models::harvest_action::{HarvestAction, HarvestParams};
use astraplani::models::travel_action::{TravelAction, TravelParams};
use astraplani::models::combat_action::{CombatAction, CombatParams};

fn start_action(world: WorldStorage, entity_id: u32, params: ActionParams) {
    assert_is_idle(world, entity_id);

    match params {
        ActionParams::Harvest(harvest_params) => {
            operations::harvest::initialize(world, entity_id, harvest_params);
            set_action_status(world, entity_id, ActionType::Harvest);
        },
        ActionParams::Travel(travel_params) => {
            operations::travel::initialize(world, entity_id, travel_params);
            set_action_status(world, entity_id, ActionType::Travel);
        },
        ActionParams::Combat(combat_params) => {
            operations::combat::initialize(world, entity_id, combat_params);
            set_action_status(world, entity_id, ActionType::Combat);
        },
    }
}
fn end_action(world: WorldStorage, entity_id: u32) {
    match get_action_type(world, entity_id) {
        ActionType::Harvest => operations::harvest::complete(world, entity_id),
        ActionType::Travel => operations::travel::complete(world, entity_id),
        ActionType::Combat => operations::combat::complete(world, entity_id),
    }
    delete_action_status(world, entity_id);
}

fn cancel_action(world: WorldStorage, entity_id: u32) {
    match get_action_type(world, entity_id) {
        ActionType::Harvest => operations::harvest::interrupt(world, entity_id),
        ActionType::Travel => operations::travel::interrupt(world, entity_id),
        ActionType::Combat => operations::combat::interrupt(world, entity_id),
    }
    delete_action_status(world, entity_id);
}

fn set_action_status(world: WorldStorage, entity_id: u32, action_type: ActionType) {
    let new_action_status = ActionStatus { entity_id, action_type };

    world.write_model(@new_action_model);
}

fn delete_action_status(world: WorldStorage, entity_id: u32) {
    let action_status: ActionStatus = world.read_model(entity_id);

    world.erase_model(@action_status);
}

