use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::utils::testing::{world::spawn_world, spawners::spawn_quasar, spawners::spawn_star};

use astraplani::models::owner::Owner;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::{Position, PositionCustomImpl};
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::vec2::{Vec2, Vec2Impl};

use astraplani::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

fn setup() -> (
    WorldStorage, ContractAddress, ContractAddress, u32, u32, ICreationSystemsDispatcher
) {
    let mut world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let (creation_address, _) = world.dns(@"creation_systems").unwrap();
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    let star_owner = contract_address_const::<'star_owner'>();
    let not_star_owner = contract_address_const::<'not_star_owner'>();

    let quasar_coords = Vec2 { x: 23, y: 32 };
    let emission_rate = 1_000_000;
    let quasar_mass = 1_000_000;
    let quasar_id = spawn_quasar(world, star_owner, quasar_coords, emission_rate, quasar_mass);

    let star_coords = Vec2 { x: 42, y: 23 };
    let star_mass = 1_000;
    let star_id = spawn_star(world, star_owner, star_coords, quasar_id, star_mass);

    world.write_model_test(@(LooshBalance { address: star_owner, balance: 1_000_000_000_000_000 }));

    (world, star_owner, not_star_owner, quasar_id, star_id, creation_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_create_asteroid_cluster_valid() {
    let (world, star_owner, _, _, star_id, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    let asteroid_cluster_id = creation_dispatcher.create_asteroid_cluster(star_id);

    let asteroid_cluster_owner: Owner = world.read_model(asteroid_cluster_id);
    assert(asteroid_cluster_owner.address == star_owner, 'invalid owner');
    let asteroid_cluster_pos: Position = world.read_model(asteroid_cluster_id);
    let star_pos: Position = world.read_model(star_id);
    assert(asteroid_cluster_pos.is_equal(world, star_pos), 'invalid coords');
    let asteroid_cluster_body: CosmicBody = world.read_model(asteroid_cluster_id);
    assert(asteroid_cluster_body.body_type == CosmicBodyType::AsteroidCluster, 'invalid body type');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_create_asteroid_cluster_no_loosh() {
    let (mut world, star_owner, _, _, star_id, creation_dispatcher) = setup();

    let loosh_balance = LooshBalance { address: star_owner, balance: 0 };

    world.write_model_test(@loosh_balance);

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    creation_dispatcher.create_asteroid_cluster(star_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('caller must own star', 'ENTRYPOINT_FAILED'))]
fn test_create_asteroid_cluster_not_star_owner() {
    let (_, _, not_star_owner, _, star_id, creation_dispatcher) = setup();

    set_contract_address(not_star_owner);
    set_account_contract_address(not_star_owner);

    creation_dispatcher.create_asteroid_cluster(star_id);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('invalid star id', 'ENTRYPOINT_FAILED'))]
fn test_create_asteroid_cluster_not_in_star() {
    let (_, star_owner, _, quasar_id, _, creation_dispatcher) = setup();

    set_contract_address(star_owner);
    set_account_contract_address(star_owner);

    creation_dispatcher.create_asteroid_cluster(quasar_id);
}
