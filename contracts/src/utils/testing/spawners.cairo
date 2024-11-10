use core::array::{ArrayTrait, SpanTrait};
use astraplani::models::{
    loosh_balance, basal_attributes, incubation, owner, position, mass, travel_action, vec2,
    dust_balance, dust_emission, dust_accretion, orbit, loosh_sink, cosmic_body, orbital_mass
};
use dojo::utils::test::{spawn_test_world};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use starknet::{ContractAddress, contract_address_const};

fn spawn_quasar(
    world: IWorldDispatcher,
    owner: ContractAddress,
    coords: vec2::Vec2,
    mass: u64,
    emission_rate: u128,
) -> u32 {
    let body_type = cosmic_body::CosmicBodyType::Quasar;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, 0, mass);

    set!(
        world,
        (dust_emission::DustEmission {
            entity: body_id, emission_rate, ARPS: 0, last_update_ts: 0,
        })
    );

    return body_id;
}

fn spawn_protostar(
    world: IWorldDispatcher,
    owner: ContractAddress,
    coords: vec2::Vec2,
    orbit_center: u32,
    mass: u64,
    creation_ts: u64,
    end_ts: u64
) -> u32 {
    let body_type = cosmic_body::CosmicBodyType::Protostar;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, orbit_center, mass);

    set!(world, (incubation::Incubation { entity: body_id, creation_ts, end_ts },));

    return body_id;
}

fn spawn_star(
    world: IWorldDispatcher,
    owner: ContractAddress,
    coords: vec2::Vec2,
    orbit_center: u32,
    mass: u64
) -> u32 {
    let body_type = cosmic_body::CosmicBodyType::Star;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, orbit_center, mass);

    return body_id;
}

fn spawn_asteroid_cluster(
    world: IWorldDispatcher,
    owner: ContractAddress,
    coords: vec2::Vec2,
    orbit_center: u32,
    mass: u64
) -> u32 {
    let body_type = cosmic_body::CosmicBodyType::AsteroidCluster;

    let body_id = spawn_cosmic_body(world, body_type, owner, coords, orbit_center, mass);

    return body_id;
}

use astraplani::models::orbital_mass::OrbitalMass;

fn spawn_cosmic_body(
    world: IWorldDispatcher,
    body_type: cosmic_body::CosmicBodyType,
    owner: ContractAddress,
    coords: vec2::Vec2,
    orbit_center: u32,
    mass: u64
) -> u32 {
    let body_id = world.uuid();

    let center_orbital_mass = get!(world, orbit_center, orbital_mass::OrbitalMass).orbital_mass;

    set!(
        world,
        (
            owner::Owner { entity: body_id, address: owner },
            cosmic_body::CosmicBody { entity: body_id, body_type },
            position::Position { entity: body_id, vec: coords },
            mass::Mass { entity: body_id, mass },
            orbit::Orbit { entity: body_id, orbit_center },
            orbital_mass::OrbitalMass {
                entity: orbit_center, orbital_mass: center_orbital_mass + mass
            }
        )
    );

    return body_id;
}
