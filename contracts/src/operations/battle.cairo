use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::utils::battle::calculate_battle_outcome;

use astraplani::models::action_status::ActionStatus;
use astraplani::models::vec2::Vec2;
use astraplani::models::position::Position;
use astraplani::models::battle::Battle;

fn initialize(world: WorldStorage, attacker_id: u32, defender_id: u32) -> u32 {
    let battle_id = world.create_entity();

    let battle = Battle {
        battle_id,
        primary_attacker: attacker_id,
        primary_defender: defender_id,
        attackers: array![attacker_id],
        defenders: array![defender_id],
        start_ts: get_block_timestamp(),
        end_ts: get_block_timestamp() + BATTLE_DURATION,
    };

    world.write_model(@battle);

    return battle_id;
}

fn calculate_and_apply_losses(world: WorldStorage, fleet_id: u32, battle_id: u32) {
    let battle: Battle = world.read_model(battle_id);
    let outcome = calculate_battle_outcome(battle);
    let loss_percentage = determine_fleet_loss_percentage(battle, fleet_id, outcome);
    let fleet = get!(world, fleet_id, FleetComposition);
    let losses = calculate_fleet_losses(fleet, loss_percentage);

    // Apply through specialized operations
    operations::fleet::deduct_losses(world, fleet_id, losses);
}

fn calculate_and_apply_losses(world: WorldStorage, fleet_id: u32, battle_id: u32,) {
    let battle: Battle = world.read_model(battle_id);
    let outcome = calculate_battle_outcome(battle);
    let loss_percentage = determine_fleet_loss_percentage(battle, fleet_id, outcome);
    let fleet = get!(world, fleet_id, FleetComposition);
    let losses = calculate_fleet_losses(fleet, loss_percentage);

    // Apply through specialized operations
    operations::fleet::deduct_losses(world, fleet_id, losses);
}
