use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use starknet::ContractAddress;
use dojo_starter::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

use dojo_starter::models::mass::Mass;
use dojo_starter::models::orbit::Orbit;
use dojo_starter::models::vec2::Vec2;
use dojo_starter::models::orbital_mass::OrbitalMass;

fn add_to_dust_pool(
    world: IWorldDispatcher, dust_dispatcher: IDustSystemsDispatcher, pool_id: u32, star_id: u32
) {
    let pool_mass = get!(world, pool_id, Mass);
    let pool_orbital_mass = get!(world, pool_id, OrbitalMass);
    let star_mass = get!(world, star_id, Mass);

    set!(
        world,
        (
            Orbit { entity: star_id, orbit_center: pool_id },
            Mass { entity: pool_id, mass: pool_mass.mass, },
            OrbitalMass { entity: pool_id, orbital_mass: pool_orbital_mass.orbital_mass + star_mass.mass, }
        )
    );

    dust_dispatcher.enter_dust_pool(star_id, pool_id);
}
