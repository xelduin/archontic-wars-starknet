use core::array::{ArrayTrait, SpanTrait};
use starknet::{ContractAddress, contract_address_const};

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::models::dust_emission::DustEmission;
use astraplani::models::incubation::Incubation;
use astraplani::models::owner::Owner;
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::position::Position;
use astraplani::models::mass::Mass;
use astraplani::models::orbit::Orbit;
use astraplani::models::orbital_mass::OrbitalMass;
use astraplani::models::vec2::Vec2;

fn spawn_quasar(
    mut world: WorldStorage, owner: ContractAddress, coords: Vec2, mass: u64, emission_rate: u128,
) -> u32 {
    let body_type = CosmicBodyType::Quasar;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, 0, mass);

    let dust_emission = DustEmission {
        entity: body_id, emission_rate, ARPS: 0, last_update_ts: 0,
    };

    world.write_model_test(@dust_emission);

    return body_id;
}

fn spawn_protostar(
    mut world: WorldStorage,
    owner: ContractAddress,
    coords: Vec2,
    orbit_center: u32,
    mass: u64,
    creation_ts: u64,
    end_ts: u64
) -> u32 {
    let body_type = CosmicBodyType::Protostar;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, orbit_center, mass);

    let incubation = Incubation { entity: body_id, creation_ts, end_ts };

    world.write_model_test(@incubation);

    return body_id;
}

fn spawn_star(
    mut world: WorldStorage, owner: ContractAddress, coords: Vec2, orbit_center: u32, mass: u64
) -> u32 {
    let body_type = CosmicBodyType::Star;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, orbit_center, mass);

    return body_id;
}

fn spawn_asteroid_cluster(
    mut world: WorldStorage, owner: ContractAddress, coords: Vec2, orbit_center: u32, mass: u64
) -> u32 {
    let body_type = CosmicBodyType::AsteroidCluster;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, orbit_center, mass);

    return body_id;
}

fn spawn_cosmic_body(
    mut world: WorldStorage,
    body_type: CosmicBodyType,
    owner: ContractAddress,
    coords: Vec2,
    orbit_center: u32,
    mass: u64
) -> u32 {
    let body_id = world.dispatcher.uuid();

    let center_orbital_mass: OrbitalMass = world.read_model(orbit_center);

    let new_owner = Owner { entity: body_id, address: owner };
    let new_cosmic_body = CosmicBody { entity: body_id, body_type };
    let new_position = Position { entity: body_id, vec: coords };
    let new_mass = Mass { entity: body_id, mass };
    let new_orbit = Orbit { entity: body_id, orbit_center };
    let new_orbital_mass = OrbitalMass {
        entity: orbit_center, orbital_mass: center_orbital_mass.orbital_mass + mass
    };

    world.write_model_test(@new_owner);
    world.write_model_test(@new_cosmic_body);
    world.write_model_test(@new_position);
    world.write_model_test(@new_mass);
    world.write_model_test(@new_orbit);
    world.write_model_test(@new_orbital_mass);

    return body_id;
}
