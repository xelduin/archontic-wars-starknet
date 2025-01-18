use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::models::vec2::{Vec2, Vec2Impl};

use astraplani::validators::action_status::assert_is_in;

fn assert_battle_is_over(mut world: WorldStorage, battle_id: u32) {
    let battle_action: BattleAction = world.read_model(battle_id);

    assert_battle_valid(world, battle_id);
    assert(get_block_timestamp() >= battle_action.end_ts, 'battle not over');
}

fn assert_battle_valid(mut world: WorldStorage, battle_id: u32) {
    let battle_action: BattleAction = world.read_model(battle_id);

    assert(battle_action.start_ts != 0, 'invalid battle id');
    assert(battle_action.end_ts != 0, 'invalid battle id');
}
