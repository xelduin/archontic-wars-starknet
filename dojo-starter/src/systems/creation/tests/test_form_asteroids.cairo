use dojo_starter::models::owner::Owner;
use dojo_starter::models::loosh_balance::LooshBalance;
use dojo_starter::models::position::Position;
use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
use dojo_starter::models::vec2::{Vec2, Vec2Impl};
use dojo_starter::models::incubation::Incubation;
use dojo_starter::models::dust_balance::DustBalance;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::orbit::Orbit;

use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_block_timestamp, set_contract_address, set_account_contract_address}
};
use starknet::contract_address_const;

use dojo_starter::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

use dojo_starter::utils::testing::{
    world::spawn_world, spawners::spawn_quasar, spawners::spawn_star,
    spawners::spawn_asteroid_cluster
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

const BASE_INCUBATION_PERIOD: u64 = 60 * 1000;

// Mock setup for the test
fn setup() -> (
    IWorldDispatcher,
    ContractAddress,
    ContractAddress,
    u32,
    u32,
    u32,
    u32,
    ICreationSystemsDispatcher
) {
    let world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let creation_address = world
        .deploy_contract('salt', creation_systems::TEST_CLASS_HASH.try_into().unwrap());
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), creation_address);

    let star_owner = contract_address_const::<'star_owner'>();
    let not_star_owner = contract_address_const::<'not_star_owner'>();

    let quasar_coords = Vec2 { x: 23, y: 32 };
    let emission_rate = 1_000_000;
    let quasar_mass = 1_000_000;
    let quasar_id = spawn_quasar(world, star_owner, quasar_coords, emission_rate, quasar_mass);

    let star_coords = Vec2 { x: 42, y: 23 };
    let star_mass = 1_000;
    let star_id = spawn_star(world, star_owner, star_coords, star_mass);

    let far_star_coords = Vec2 { x: 1, y: 2 };
    let far_star_id = spawn_star(world, star_owner, far_star_coords, star_mass);

    let asteroid_cluster_coords = Vec2 { x: 1, y: 2 };
    let asteroid_cluster_mass = 100;
    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, star_owner, asteroid_cluster_coords, asteroid_cluster_mass
    );

    set!(
        world,
        (
            Orbit { entity: asteroid_cluster_id, orbit_center: star_id },
            DustBalance { entity: star_id, balance: 1_000_000_000_000_000 },
            DustBalance { entity: far_star_id, balance: 1_000_000_000_000_000 },
            DustBalance { entity: quasar_id, balance: 1_000_000_000_000_000 }
        )
    );

    (
        world,
        star_owner,
        not_star_owner,
        quasar_id,
        star_id,
        far_star_id,
        asteroid_cluster_id,
        creation_dispatcher
    )
}

#[test]
#[available_gas(3000000000000)]
fn test_form_asteroids_valid() {
    let (world, star_owner, _, _, star_id, _, asteroid_cluster_id, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let initial_mass = get!(world, asteroid_cluster_id, Mass);
    let mass_increase = 10;

    creation_dispatcher.form_asteroids(star_id, asteroid_cluster_id, mass_increase);

    let new_mass = get!(world, asteroid_cluster_id, Mass);
    assert(new_mass.mass == initial_mass.mass + mass_increase, 'failed to increase mass');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient dust', 'ENTRYPOINT_FAILED'))]
fn test_form_asteroids_no_dust() {
    let (world, star_owner, _, _, star_id, _, asteroid_cluster_id, creation_dispatcher) = setup();

    set!(world, DustBalance { entity: star_id, balance: 0 });

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let mass_increase = 10;

    creation_dispatcher.form_asteroids(star_id, asteroid_cluster_id, mass_increase);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid star id', 'ENTRYPOINT_FAILED'))]
fn test_form_asteroids_not_star() {
    let (_, star_owner, _, quasar_id, _, _, asteroid_cluster_id, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let mass_increase = 10;

    creation_dispatcher.form_asteroids(quasar_id, asteroid_cluster_id, mass_increase);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('caller must own star', 'ENTRYPOINT_FAILED'))]
fn test_form_asteroids_not_owner() {
    let (_, _, not_star_owner, _, star_id, _, asteroid_cluster_id, creation_dispatcher) = setup();

    set_contract_address(not_star_owner);
    set_account_contract_address(not_star_owner);

    let mass_increase = 10;

    creation_dispatcher.form_asteroids(star_id, asteroid_cluster_id, mass_increase);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid asteroid cluster id', 'ENTRYPOINT_FAILED'))]
fn test_form_asteroids_not_asteroid_cluster() {
    let (_, star_owner, _, _, star_id, far_star_id, _, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let mass_increase = 10;

    creation_dispatcher.form_asteroids(star_id, far_star_id, mass_increase);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('asteroid cluster not in orbit', 'ENTRYPOINT_FAILED'))]
fn test_form_asteroids_not_in_orbit() {
    let (_, star_owner, _, _, _, far_star_id, asteroid_cluster_id, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let mass_increase = 10;

    creation_dispatcher.form_asteroids(far_star_id, asteroid_cluster_id, mass_increase);
}
