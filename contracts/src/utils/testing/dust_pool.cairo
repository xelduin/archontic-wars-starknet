use starknet::ContractAddress;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

use astraplani::models::mass::Mass;
use astraplani::models::orbit::Orbit;
use astraplani::models::vec2::Vec2;
use astraplani::models::orbital_mass::OrbitalMass;

fn add_to_dust_pool(
    mut world: WorldStorage, dust_dispatcher: IDustSystemsDispatcher, pool_id: u32, star_id: u32
) {
    let star_mass: Mass = world.read_model(star_id);
    let pool_mass: Mass = world.read_model(pool_id);
    let pool_orbital_mass: OrbitalMass = world.read_model(pool_id);

    let new_star_orbit = Orbit { entity: star_id, orbit_center: pool_id };
    let new_pool_mass = Mass { entity: pool_id, mass: pool_mass.mass, };
    let new_pool_orbital_mass = OrbitalMass {
        entity: pool_id, orbital_mass: pool_orbital_mass.orbital_mass + star_mass.mass,
    };

    world.write_model_test(@new_star_orbit);
    world.write_model_test(@new_pool_mass);
    world.write_model_test(@new_pool_orbital_mass);

    dust_dispatcher.enter_dust_pool(star_id, pool_id);
}
