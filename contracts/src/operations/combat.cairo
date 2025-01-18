use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::operations;

use astraplani::validators::battle::assert_battle_ended;

use astraplani::utils::battle::get_entity_battle;
use astraplani::utils::battle::calculate_fleet_losses;

fn initialize(world: WorldStorage, asteroid_id: u32, params: CombatParams) {
    let new_combat_action = CombatAction { entity_id: asteroid_id, params };

    world.write_model(@new_combat_action);
}

fn complete(world: WorldStorage, asteroid_id: u32) {
    let battle = get_entity_battle(world, asteroid_id);
    assert_battle_ended(world, battle.battle_id);

    operations::battle::calculate_and_apply_losses(world, asteroid_id, battle.battle_id);
    operations::battle::caluclate_and_apply_rewards(world, asteroid_id, battle.battle_id);

    let combat_action = get_combat_action(world, asteroid_id);
    world.erase_model(@combat_action);
}

fn interrupt(world: WorldStorage, asteroid_id: u32) {
    assert_harvest_not_ended(world, asteroid_id);

    let harvest_action = get_harvest_action(world, asteroid_id);
    let partial_harvest = calculate_partial_harvest_amount(world, asteroid_id);

    operations::dust::transfer_dust(
        world, asteroid_id, harvest_action.dust_cloud_id, partial_harvest
    );

    world.erase_model(@harvest_action);
}

