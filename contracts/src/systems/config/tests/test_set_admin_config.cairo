use astraplani::models::config::AdminConfig;
use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use astraplani::systems::config::contracts::config_systems::{
    config_systems, IConfigSystemsDispatcher, IConfigSystemsDispatcherTrait
};

use astraplani::utils::testing::{world::spawn_world};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use astraplani::constants::ADMIN_CONFIG_ID;

// Mock setup for the test
fn setup() -> (IWorldDispatcher, ContractAddress, ContractAddress, IConfigSystemsDispatcher) {
    let world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let config_address = world
        .deploy_contract('salt', config_systems::TEST_CLASS_HASH.try_into().unwrap());
    let config_dispatcher = IConfigSystemsDispatcher { contract_address: config_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), config_address);

    // Define initial body ID and contract addresses for old and new owners
    let admin = contract_address_const::<'admin'>();
    let non_admin = contract_address_const::<'non_admin'>();

    // Return the initial world state, body ID, and contract addresses
    (world, admin, non_admin, config_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_set_admin_config_valid() {
    let (world, admin, non_admin, config_dispatcher) = setup();

    config_dispatcher.set_admin_config(ADMIN_CONFIG_ID, admin);

    set_contract_address(admin);
    set_account_contract_address(admin);

    let admin_config = get!(world, ADMIN_CONFIG_ID, AdminConfig);
    assert(admin_config.admin_address == admin, 'failed to set new admin');

    config_dispatcher.set_admin_config(ADMIN_CONFIG_ID, non_admin);

    let new_admin_config = get!(world, ADMIN_CONFIG_ID, AdminConfig);
    assert(new_admin_config.admin_address == non_admin, 'failed to set new admin');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not admin', 'ENTRYPOINT_FAILED'))]
fn test_set_admin_config_non_admin() {
    let (_, admin, non_admin, config_dispatcher) = setup();

    config_dispatcher.set_admin_config(ADMIN_CONFIG_ID, admin);

    set_contract_address(non_admin);
    set_account_contract_address(non_admin);

    config_dispatcher.set_admin_config(ADMIN_CONFIG_ID, non_admin);
}
