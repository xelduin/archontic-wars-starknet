use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::models::owner::Owner;
use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use astraplani::systems::authority::contracts::authority_systems::{
    authority_systems, IAuthoritySystemsDispatcher, IAuthoritySystemsDispatcherTrait
};

use astraplani::utils::testing::{world::spawn_world};


// Mock setup for the test
fn setup() -> (WorldStorage, u32, ContractAddress, ContractAddress, IAuthoritySystemsDispatcher) {
    let mut world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let (authority_address, _) = world.dns(@"authority_systems").unwrap();
    let authority_dispatcher = IAuthoritySystemsDispatcher { contract_address: authority_address };

    // Define initial body ID and contract addresses for old and new owners
    let body_id = 1;
    let old_owner = contract_address_const::<'old_owner'>();
    let new_owner = contract_address_const::<'new_owner'>();

    let owner_model = Owner { entity: body_id, address: old_owner };

    world.write_model_test(@owner_model);

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
    let new_owner_data: Owner = world.read_model(body_id);
    assert(new_owner_data.address == new_owner, 'not owner');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not owner', 'ENTRYPOINT_FAILED'))]
fn test_transfer_ownership_unsuccess() {
    let (_, body_id, _, new_owner, authority_dispatcher) = setup();

    // Set the contract address for the caller as the old owner
    set_contract_address(new_owner);
    set_account_contract_address(new_owner);

    // Call the transfer_ownership function from the old owner
    authority_dispatcher.transfer_ownership(body_id, new_owner);
}
