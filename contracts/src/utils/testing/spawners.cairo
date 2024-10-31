use core::array::{ArrayTrait, SpanTrait};
use astraplani::models::{
    loosh_balance, basal_attributes, incubation, owner, position, mass, travel_action, vec2,
    dust_balance, dust_emission, dust_accretion, orbit, loosh_sink, cosmic_body
};
use dojo::utils::test::{spawn_test_world};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use starknet::{ContractAddress, contract_address_const};


fn spawn_quasar(
    world: IWorldDispatcher,
    owner: ContractAddress,
    coords: vec2::Vec2,
    emission_rate: u128,
    mass: u64
) -> u32 {
    let body_id = world.uuid();

    set!(
        world,
        (
            owner::Owner { entity: body_id, address: owner },
            cosmic_body::CosmicBody {
                entity: body_id, body_type: cosmic_body::CosmicBodyType::Quasar
            },
            mass::Mass { entity: body_id, mass },
            position::Position { entity: body_id, vec: coords }
        )
    );

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
    star_mass: u64,
    creation_ts: u64,
    end_ts: u64
) -> u32 {
    let body_id = world.uuid();

    set!(
        world,
        (
            owner::Owner { entity: body_id, address: owner },
            cosmic_body::CosmicBody {
                entity: body_id, body_type: cosmic_body::CosmicBodyType::Protostar
            },
            position::Position { entity: body_id, vec: coords },
            mass::Mass { entity: body_id, mass: star_mass },
            incubation::Incubation { entity: body_id, creation_ts, end_ts }
        )
    );

    return body_id;
}

fn spawn_star(
    world: IWorldDispatcher, owner: ContractAddress, coords: vec2::Vec2, star_mass: u64
) -> u32 {
    let body_id = world.uuid();

    set!(
        world,
        (
            owner::Owner { entity: body_id, address: owner },
            cosmic_body::CosmicBody {
                entity: body_id, body_type: cosmic_body::CosmicBodyType::Star
            },
            position::Position { entity: body_id, vec: coords },
            mass::Mass { entity: body_id, mass: star_mass },
        )
    );

    return body_id;
}

use astraplani::models::mass::Mass;
use astraplani::models::position::Position;

fn spawn_asteroid_cluster(
    world: IWorldDispatcher, owner: ContractAddress, coords: vec2::Vec2, cluster_mass: u64
) -> u32 {
    let body_id = world.uuid();

    set!(
        world,
        (
            owner::Owner { entity: body_id, address: owner },
            cosmic_body::CosmicBody {
                entity: body_id, body_type: cosmic_body::CosmicBodyType::AsteroidCluster
            },
            position::Position { entity: body_id, vec: coords },
            mass::Mass { entity: body_id, mass: cluster_mass },
        )
    );

    return body_id;
}
