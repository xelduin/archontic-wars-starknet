use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::Vec2;

use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo_starter::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

use dojo_starter::utils::testing::{spawn_world, spawn_galaxy, spawn_star, spawn_asteroid_cluster};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (IWorldDispatcher, ContractAddress, IDustSystemsDispatcher) {
    let world = spawn_world();

    let dust_address = world
        .deploy_contract('salt', dust_systems::TEST_CLASS_HASH.try_into().unwrap());
    let dust_dispatcher = IDustSystemsDispatcher { contract_address: dust_address };

    let movement_address = world
        .deploy_contract('salt', movement_systems::TEST_CLASS_HASH.try_into().unwrap());
    let movement_dispatcher = IDustSystemsDispatcher { contract_address: movement_address };


    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), dust_address);

    // Accounts
    let sender_owner = contract_address_const::<'sender_owner'>();

    // SET UP DUST POOL
    let emission_rate = 1000;
    let galaxy_id = spawn_galaxy(world, sender_owner, emission_rate);
    let star_mass = 200;
    let star_id = spawn_star(world, sender_owner, Vec2 {100, 100}, star_mass);

    dust_dispatcher.enter_dust_pool()

    (world, sender_owner, dust_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_claim_dust_valid() {
    let (world, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_balance = get!(world, sender_owner, LooshBalance);

    let loosh_amount = old_sender_balance / 2;
    loosh_dispatcher.burn_loosh(loosh_amount);

    let new_sender_balance = get!(world, sender_owner, LooshBalance);
    assert(
        old_sender_balance.balance == old_sender_balance.balance - loosh_amount,
        'sender loosh not decreased'
    );
}
