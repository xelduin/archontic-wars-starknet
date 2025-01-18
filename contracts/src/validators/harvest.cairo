use starknet::{ContractAddress};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::utils::harvest::get_harvest_action;

fn assert_harvest_ended(world: WorldStorage, entity_id: u32) {
    let harvest_action = get_harvest_action(world, entity_id);

    assert(get_block_timestamp() >= harvest_action.end_ts, 'harvest not ended')
}

fn assert_harvest_not_ended(world: WorldStorage, entity_id: u32) {
    let harvest_action = get_harvest_action(world, entity_id);

    assert(get_block_timestamp() < harvest_action.end_ts, 'harvest has ended')
}
