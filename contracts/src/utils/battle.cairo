use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::action_status::{ActionStatus, ActionType};

fn get_entity_battle(world: WorldStorage, entity_id: u32) -> Battle {
    let combat_action = get_combat_action(world, entity_id);

    assert_battle_valid(world, combat_action.params.battle_id);

    let battle: Battle = world.read_model(combat_action.params.battle_id);

    return battle;
}

fn calculate_battle_dust_generation(world: WorldStorage, battle_id: u32) -> u128 {
    let battle: Battle = world.read_model(battle_id);
    assert_battle_valid(world, battle.battle_id);

    let outcome = calculate_battle_outcome(battle);

    let winner_dust = if outcome.winner == BattleWinner::Attacker {
        calculate_dust_from_fleet(battle.attacker_power, outcome.victor_losses)
    } else {
        calculate_dust_from_fleet(battle.defender_power, outcome.victor_losses)
    };

    // Calculate dust from loser's losses (total fleet destruction)
    let loser_dust = if outcome.winner == BattleWinner::Attacker {
        calculate_dust_from_fleet(battle.defender_power, 100) // Complete destruction
    } else {
        calculate_dust_from_fleet(battle.attacker_power, 100) // Complete destruction
    };

    winner_dust + loser_dust
}

fn calculate_fleet_losses(
    fleet: FleetComposition,
    loss_percentage: u8
) -> FleetComposition {
    assert(loss_percentage <= 100, 'Invalid loss percentage');
    
    return FleetComposition {
        scouts: (fleet.scouts * loss_percentage.into()) / 100,
        harvesters: (fleet.harvesters * loss_percentage.into()) / 100,
        carriers: (fleet.carriers * loss_percentage.into()) / 100,
        dreadnoughts: (fleet.dreadnoughts * loss_percentage.into()) / 100
    }
}