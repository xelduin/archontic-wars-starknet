use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::Vec2;

use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo_starter::systems::mass::contracts::mass_systems::{
    mass_systems, IMassSystemsDispatcher, IMassSystemsDispatcherTrait
};

use dojo_starter::utils::testing::{spawn_world, spawn_star, spawn_asteroid_cluster};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (
    IWorldDispatcher, u32, u32, u32, u32, ContractAddress, ContractAddress, IMassSystemsDispatcher
) {
    let world = spawn_world();

    let mass_address = world
        .deploy_contract('salt', mass_systems::TEST_CLASS_HASH.try_into().unwrap());
    let mass_dispatcher = IMassSystemsDispatcher { contract_address: mass_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), mass_address);

    let sender_owner = contract_address_const::<'sender_owner'>();
    let receiver_owner = contract_address_const::<'receiver_owner'>();

    let sender_star_id = spawn_star(world, sender_owner, Vec2 { x: 20, y: 20 }, 1000);
    let sender_asteroid_id = spawn_asteroid_cluster(
        world, sender_owner, Vec2 { x: 20, y: 20 }, 100
    );
    let receiver_asteroid_id = spawn_asteroid_cluster(
        world, receiver_owner, Vec2 { x: 20, y: 20 }, 100
    );
    let far_asteroid_id = spawn_asteroid_cluster(world, sender_owner, Vec2 { x: 12, y: 20 }, 100);

    (
        world,
        sender_star_id,
        sender_asteroid_id,
        receiver_asteroid_id,
        far_asteroid_id,
        sender_owner,
        receiver_owner,
        mass_dispatcher
    )
}

#[test]
#[available_gas(3000000000000)]
fn test_transfer_mass() {
    let (world, _, sender_asteroid_id, receiver_asteroid_id, _, sender_owner, _, mass_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_mass = get!(world, sender_asteroid_id, Mass);
    let old_receiver_mass = get!(world, receiver_asteroid_id, Mass);

    let mass_transfer = old_sender_mass.mass / 2;

    mass_dispatcher.transfer_mass(sender_asteroid_id, receiver_asteroid_id, mass_transfer);

    let new_mass = get!(world, sender_asteroid_id, Mass);
    assert(new_mass.mass == old_sender_mass.mass - mass_transfer, 'sender mass not decreased');

    let new_receiver_mass = get!(world, receiver_asteroid_id, Mass);
    assert(
        new_receiver_mass.mass == old_receiver_mass.mass + mass_transfer,
        'receiver mass not increased'
    );
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not owner', 'ENTRYPOINT_FAILED'))]
fn test_transfer_mass_not_owner() {
    let (
        world, _, sender_asteroid_id, receiver_asteroid_id, _, _, receiver_owner, mass_dispatcher
    ) =
        setup();

    set_contract_address(receiver_owner);
    set_account_contract_address(receiver_owner);

    let old_sender_mass = get!(world, sender_asteroid_id, Mass);

    let mass_transfer = old_sender_mass.mass / 2;

    mass_dispatcher.transfer_mass(sender_asteroid_id, receiver_asteroid_id, mass_transfer);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in proximity', 'ENTRYPOINT_FAILED'))]
fn test_transfer_mass_to_far_asteroid() {
    let (world, _, sender_asteroid_id, _, far_asteroid_id, sender_owner, _, mass_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_mass = get!(world, sender_asteroid_id, Mass);

    let mass_transfer = old_sender_mass.mass / 2;

    mass_dispatcher.transfer_mass(sender_asteroid_id, far_asteroid_id, mass_transfer);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in proximity', 'ENTRYPOINT_FAILED'))]
fn test_transfer_mass_from_far_asteroid() {
    let (world, _, _, receiver_asteroid_id, far_asteroid_id, sender_owner, _, mass_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_mass = get!(world, far_asteroid_id, Mass);

    let mass_transfer = old_sender_mass.mass / 2;

    mass_dispatcher.transfer_mass(far_asteroid_id, receiver_asteroid_id, mass_transfer);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not asteroid cluster', 'ENTRYPOINT_FAILED'))]
fn test_transfer_mass_from_non_asteroid() {
    let (world, sender_star_id, _, receiver_asteroid_id, _, sender_owner, _, mass_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_mass = get!(world, sender_star_id, Mass);

    let mass_transfer = old_sender_mass.mass / 2;

    mass_dispatcher.transfer_mass(sender_star_id, receiver_asteroid_id, mass_transfer);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not enough mass', 'ENTRYPOINT_FAILED'))]
fn test_transfer_mass_from_insufficient() {
    let (world, _, sender_asteroid_id, receiver_asteroid_id, _, sender_owner, _, mass_dispatcher) =
        setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_mass = get!(world, sender_asteroid_id, Mass);

    let mass_transfer = old_sender_mass.mass;

    mass_dispatcher.transfer_mass(sender_asteroid_id, receiver_asteroid_id, mass_transfer);
}
