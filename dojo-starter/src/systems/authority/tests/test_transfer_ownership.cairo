use dojo_starter::models::owner::Owner;
use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo_starter::systems::authority::contracts::authority_systems::{
    authority_systems, IAuthoritySystemsDispatcher, IAuthoritySystemsDispatcherTrait
};

use dojo_starter::utils::testing::{spawn_world};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (
    IWorldDispatcher, u32, ContractAddress, ContractAddress, IAuthoritySystemsDispatcher
) {
    let world = spawn_world(); // Assume spawn_world sets up the initial world state

    let authority_address = world
        .deploy_contract('salt', authority_systems::TEST_CLASS_HASH.try_into().unwrap());
    let authority_dispatcher = IAuthoritySystemsDispatcher { contract_address: authority_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), authority_address);

    // Define initial body ID and contract addresses for old and new owners
    let body_id = 1;
    let old_owner = contract_address_const::<'old_owner'>();
    let new_owner = contract_address_const::<'new_owner'>();

    set!(world, Owner { entity: body_id, address: old_owner });

    // Return the initial world state, body ID, and contract addresses
    (world, body_id, old_owner, new_owner, authority_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_transfer_ownership_success() {
    let (world, body_id, old_owner, new_owner, authority_dispatcher) = setup();

    // Set the contract address for the caller as the old owner
    set_contract_address(old_owner);
    set_account_contract_address(old_owner);

    // Call the transfer_ownership function from the old owner
    authority_dispatcher.transfer_ownership(body_id, new_owner);

    // Check that the ownership was successfully transferred
    let new_owner_data = get!(world, body_id, Owner);
    assert(new_owner_data.address == new_owner, 'not owner');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not owner', 'ENTRYPOINT_FAILED'))]
fn test_transfer_ownership_unsuccess() {
    let (world, body_id, old_owner, new_owner, authority_dispatcher) = setup();

    // Set the contract address for the caller as the old owner
    set_contract_address(new_owner);
    set_account_contract_address(new_owner);

    // Call the transfer_ownership function from the old owner
    authority_dispatcher.transfer_ownership(body_id, new_owner);
}
