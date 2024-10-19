use dojo_starter::models::owner::Owner;
use dojo_starter::models::loosh_balance::LooshBalance;
use dojo_starter::models::position::Position;
use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
use dojo_starter::models::vec2::{Vec2, Vec2Impl};
use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo_starter::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

use dojo_starter::utils::testing::{world::spawn_world};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (IWorldDispatcher, ContractAddress, ICreationSystemsDispatcher) {
    let world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let creation_address = world
        .deploy_contract('salt', creation_systems::TEST_CLASS_HASH.try_into().unwrap());
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), creation_address);

    let player = contract_address_const::<'old_owner'>();

    set!(world, (LooshBalance { address: player, balance: 1_000_000_000_000_000 }));

    (world, player, creation_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_create_galaxy_valid() {
    let (world, player, creation_dispatcher) = setup();

    set_contract_address(player);
    set_account_contract_address(player);

    let coords = Vec2 { x: 20, y: 21 };
    let galaxy_id = creation_dispatcher.create_galaxy(coords);

    let galaxy_owner = get!(world, galaxy_id, Owner);
    assert(galaxy_owner.address == player, 'invalid owner');
    let galaxy_coords = get!(world, galaxy_id, (Position));
    assert(galaxy_coords.vec.is_equal(coords), 'invalid coords');
    let galaxy_body = get!(world, galaxy_id, (CosmicBody));
    assert(galaxy_body.body_type == CosmicBodyType::Galaxy, 'invalid body type');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_create_galaxy_no_loosh() {
    let (world, player, creation_dispatcher) = setup();

    set!(world, LooshBalance { address: player, balance: 0 });

    // Set the contract address for the caller as the old owner
    set_contract_address(player);
    set_account_contract_address(player);

    // Call the transfer_ownership function from the old owner
    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_galaxy(coords);
}
