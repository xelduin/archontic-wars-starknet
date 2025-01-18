use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::position::Position;
use astraplani::models::config::PneumaCostsConfig;

use astraplani::constants::PNEUMA_COSTS_CONFIG_ID;

fn get_dust_carry_capacity(world: WorldStorage, entity_id: u32) -> u128 {
    let dust_config: DustConfig = world.read_model(DUST_CONFIG_ID);
    let entity_type: CosmicBody = world.read_model(entity_id);

    match entity_type {
        CosmicBodyType::Star => {
            // Stars' capacity depends on stability
            let star_stability: StarStability = world.read_model(entity_id);

            // Higher stability = higher capacity
            // At 100% stability: multiplier = 1.5
            // At 20% stability: multiplier = 1.0
            let stability_bonus = ((star_stability.stability - 20) * 5) / 80; // 0-50% bonus
            let multiplier = 100 + stability_bonus;

            (dust_config.base_star_dust_capacity * multiplier) / 100
        },
        CosmicBodyType::Asteroid => {
            // Asteroid capacity scales with mass
            let asteroid_mass: Mass = world.read_model(entity_id);
            let config: AsteroidConfig = world.read_model(ASTEROID_CONFIG_ID);

            asteroid_mass.mass * config.asteroid_dust_capacity_per_mass
        },
        CosmicBodyType::DustCloud => {
            // Dust clouds have "infinite" capacity (use max u128)
            0xffffffffffffffffffffffffffffffff
        }
    }
}
