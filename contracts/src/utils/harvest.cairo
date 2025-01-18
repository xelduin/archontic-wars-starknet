use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::utils::action::get_action_progress;

use astraplani::models::action_status::{ActionStatus, ActionType};
use astraplani::models::harvest_action::{HarvestAction};

fn get_harvest_action(world: WorldStorage, entity_id: u32) -> HarvestAction {
    let action_status: ActionStatus = world.read_model(entity_id);

    if action_status.action_type != ActionType::Harvest {
        panic!('no harvest action found');
    }

    let harvest_action: HarvestAction = world.read_model(entity_id);

    return harvest_action;
}

fn calculate_harvest_amount(world: WorldStorage, entity_id: u32) -> u128 {
    let harvest_action = get_harvest_action(world, entity_id);
    let current_time = get_block_timestamp();

    if current_time >= harvest_action.end_ts {
        return harvest_action.params.amount;
    }

    if current_time <= harvest_action.start_ts {
        return 0;
    }

    let (elapsed, total_duration) = get_action_progress(
        current_time, harvest_action.start_ts, harvest_action.end_ts
    );

    return harvest_action.params.amount * elapsed / total_duration;
}

fn get_actual_harvest_amount(world: WorldStorage, entity_id: u32) -> u128 {
    let harvest_action = get_harvest_action(world, entity_id);

    let dust_cloud_balance = get_dust_balance(world, harvest_action.dust_cloud_id);
    let expected_harvest = calculate_harvest_amount(world, entity_id);

    if dust_cloud_balance >= expected_harvest {
        return expected_harvest;
    } else {
        return dust_cloud_balance;
    }
}
