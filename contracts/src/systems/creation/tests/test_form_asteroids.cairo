use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_block_timestamp, set_contract_address, set_account_contract_address}
};
use starknet::contract_address_const;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::utils::testing::constants::{
    BASE_DUST_EMISSION_RATE, MASS_TO_DUST_CONVERSION, BASE_QUASAR_MASS, BASE_STAR_MASS
};
use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_quasar, spawners::spawn_star,
    spawners::spawn_asteroid_cluster
};

use astraplani::models::owner::Owner;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::Position;
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::incubation::Incubation;
use astraplani::models::dust_balance::DustBalance;
use astraplani::models::mass::Mass;
use astraplani::models::orbit::Orbit;

use astraplani::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

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

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), creation_address);

    let star_owner = contract_address_const::<'star_owner'>();
    let not_star_owner = contract_address_const::<'not_star_owner'>();

    let quasar_coords = Vec2 { x: 23, y: 32 };
    let quasar_id = spawn_quasar(
        world, star_owner, quasar_coords, BASE_QUASAR_MASS, BASE_DUST_EMISSION_RATE
    );

    let star_coords = Vec2 { x: 42, y: 23 };
    let star_id = spawn_star(world, star_owner, star_coords, quasar_id, BASE_STAR_MASS);

    let far_star_coords = Vec2 { x: 1, y: 2 };
    let far_star_id = spawn_star(world, star_owner, far_star_coords, quasar_id, BASE_STAR_MASS);

    let asteroid_cluster_mass = 100;
    let asteroid_cluster_id = spawn_asteroid_cluster(
        world, star_owner, star_coords, quasar_id, asteroid_cluster_mass
    );

    set!(
        world,
        (
            DustBalance { entity: star_id, balance: 1_000_000_000 * MASS_TO_DUST_CONVERSION },
            DustBalance { entity: far_star_id, balance: 1_000_000_000 * MASS_TO_DUST_CONVERSION },
            DustBalance { entity: quasar_id, balance: 1_000_000_000 * MASS_TO_DUST_CONVERSION }
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
#[should_panic(expected: ('asteroid cluster too far', 'ENTRYPOINT_FAILED'))]
fn test_form_asteroids_not_in_proximity() {
    let (_, star_owner, _, _, _, far_star_id, asteroid_cluster_id, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let mass_increase = 10;

    creation_dispatcher.form_asteroids(far_star_id, asteroid_cluster_id, mass_increase);
}
