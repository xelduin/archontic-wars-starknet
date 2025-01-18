use starknet::{ContractAddress};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::utils::travel::get_travel_action;

fn assert_travel_ended(world: WorldStorage, entity_id: u32) {
    let travel_action = get_travel_action(world, entity_id);

    assert(get_block_timestamp() >= travel_action.end_ts, 'travel not ended')
}

fn assert_travel_not_ended(world: WorldStorage, entity_id: u32) {
    let travel_action = get_travel_action(world, entity_id);

    assert(get_block_timestamp() < travel_action.end_ts, 'travel has ended')
}
