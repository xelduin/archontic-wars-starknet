use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::position::Position;
use astraplani::models::config::DustCostsConfig;

use astraplani::constants::DUST_COSTS_CONFIG_ID;
use astraplani::constants::STABILITY_MODIFIER_CONFIG_ID;

fn get_mass_creation_dust_cost(world: WorldStorage, star_id: u32, mass: u128) -> u128 {
    let dust_costs_config: DustCostsConfig = world.read_model(DUST_COSTS_CONFIG_ID);
    let stability_config: StabilityModifierConfig = world.read_model(STABILITY_MODIFIER_CONFIG_ID);
    let star: StarStability = world.read_model(star_id);

    let base_cost = mass * dust_costs_config.base_dust_per_mass;

    // At 100% stability: multiplier = 1.0
    // At 20% stability: multiplier = 2.0
    let stability_percentage = star.stability; // 20-100
    let stability_delta = 100 - stability_percentage; // 0-80
    let multiplier = 100 + (stability_delta * stability_config.cost_multiplier_per_stability_point);

    let final_cost = (base_cost * multiplier) / 100;

    return final_cost;
}

fn get_fleet_creation_dust_cost(world: WorldStorage, star_id: u32, fleet: FleetComposition) -> {

}
