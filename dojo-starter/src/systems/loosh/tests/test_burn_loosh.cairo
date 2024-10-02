use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::Vec2;

use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo_starter::systems::loosh::contracts::loosh_systems::{
    loosh_systems, ILooshSystemsDispatcher, ILooshSystemsDispatcherTrait
};

use dojo_starter::utils::testing::{spawn_world, spawn_star, spawn_asteroid_cluster};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (IWorldDispatcher, ContractAddress, ILooshSystemsDispatcher) {
    let world = spawn_world();

    let loosh_address = world
        .deploy_contract('salt', loosh_systems::TEST_CLASS_HASH.try_into().unwrap());
    let loosh_dispatcher = ILooshSystemsDispatcher { contract_address: loosh_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), loosh_address);

    let sender_owner = contract_address_const::<'sender_owner'>();

    set!(world, LooshBalance { address: sender_owner, balance: 1000 });

    (world, sender_owner, loosh_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_burn_loosh() {
    let (world, sender_owner, receiver_owner, loosh_dispatcher) = setup();

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

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient balance', 'ENTRYPOINT_FAILED'))]
fn test_transfer_loosh_above_balance() {
    let (world, sender_owner, receiver_owner, loosh_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_balance = get!(world, sender_owner, LooshBalance);

    let loosh_amount = old_sender_balance + 1;
    loosh_dispatcher.burn_loosh(receiver_owner, loosh_amount);
}
