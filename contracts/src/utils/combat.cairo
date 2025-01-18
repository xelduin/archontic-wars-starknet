use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::config::AsteroidAttackRangeConfig;
use astraplani::models::action_status::{ActionType, ActionStatus};
use astraplani::models::combat_action::{CombatAction};

use astraplani::constants::{ASTEROID_ATTACK_RANGE_CONFIG_ID, ASTEROID_MASS_THRESHOLD_CONFIG_ID};

use astraplani::utils::travel::get_pneuma_travel_cost;

fn get_combat_action(world: WorldStorage, entity_id: u32) -> CombatAction {
    let action_status: ActionStatus = world.read_model(entity_id);

    if action_status.action_type != ActionType::Combat {
        panic!('no combat action found');
    }

    let combat_action: CombatAction = world.read_model(entity_id);

    return combat_action;
}

fn get_attack_range(world: WorldStorage, fleet_id: u32) -> u16 {
    let mass_threshold_config: AsteroidMassThresholds = world
        .read_model(ASTEROID_MASS_THRESHOLD_CONFIG_ID);
    let attack_range_config: AsteroidAttackRangeConfig = world
        .read_model(ASTEROID_ATTACK_RANGE_CONFIG_ID);
    let asteroid_mass: Mass = world.read_model(fleet_id);

    let base_range = if asteroid_mass >= mass_threshold_config.carrier {
        attack_range_config.dreadnought // Dreadnought
    } else if asteroid_mass >= mass_threshold_config.harvester {
        attack_range_config.carrier // Carrier
    } else if asteroid_mass >= mass_threshold_config.scout {
        attack_range_config.harvester // Harvester
    } else {
        attack_range_config.scout // Scout
    };

    return base_multiplier;
}

fn get_pneuma_attack_cost(world: WorldStorage, attacker_id: u32, defender_id: u32) -> u128 {
    let attacker_pos: Position = world.read_model(attacker_id);
    let defender_pos: Position = world.read_model(defender_id);

    let pneuma_travel_cost = get_pneuma_travel_cost(world, attacker_pos.vec, defender_pos.vec);

    return pneuma_travel_cost;
}
