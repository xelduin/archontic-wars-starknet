use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::constants::ADMIN_CONFIG_ID;
use astraplani::utils::testing::{world::spawn_world};

use astraplani::models::owner::Owner;
use astraplani::models::loosh_balance::LooshBalance;
use astraplani::models::position::Position;
use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::config::AdminConfig;

use astraplani::systems::creation::contracts::creation_systems::{
    creation_systems, ICreationSystemsDispatcher, ICreationSystemsDispatcherTrait
};

fn setup() -> (WorldStorage, ContractAddress, ContractAddress, ICreationSystemsDispatcher) {
    let mut world = spawn_world(); // Assume world::spawn_world sets up the initial world state

    let (creation_address, _) = world.dns(@"creation_systems").unwrap();
    let creation_dispatcher = ICreationSystemsDispatcher { contract_address: creation_address };

    let admin = contract_address_const::<'admin'>();
    let non_admin = contract_address_const::<'non_admin'>();

    let loosh_balance = LooshBalance { address: admin, balance: 1_000_000_000_000_000 };
    let admin_config = AdminConfig { config_id: ADMIN_CONFIG_ID, admin_address: admin };

    world.write_model_test(@loosh_balance);
    world.write_model_test(@admin_config);

    (world, admin, non_admin, creation_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_create_quasar_valid() {
    let (world, admin, _, creation_dispatcher) = setup();

    set_contract_address(admin);
    set_account_contract_address(admin);

    let coords = Vec2 { x: 20, y: 21 };
    let quasar_id = creation_dispatcher.create_quasar(coords);

    let quasar_owner = get!(world, quasar_id, Owner);
    assert(quasar_owner.address == admin, 'invalid owner');
    let quasar_coords = get!(world, quasar_id, (Position));
    assert(quasar_coords.vec.is_equal(coords), 'invalid coords');
    let quasar_body = get!(world, quasar_id, (CosmicBody));
    assert(quasar_body.body_type == CosmicBodyType::Quasar, 'invalid body type');
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('insufficient loosh', 'ENTRYPOINT_FAILED'))]
fn test_create_quasar_no_loosh() {
    let (world, admin, _, creation_dispatcher) = setup();

    set!(world, LooshBalance { address: admin, balance: 0 });

    // Set the contract address for the caller as the old owner
    set_contract_address(admin);
    set_account_contract_address(admin);

    // Call the transfer_ownership function from the old owner
    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_quasar(coords);
}

#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not admin', 'ENTRYPOINT_FAILED'))]
fn test_create_quasar_not_admin() {
    let (_, _, non_admin, creation_dispatcher) = setup();

    // Set the contract address for the caller as the old owner
    set_contract_address(non_admin);
    set_account_contract_address(non_admin);

    // Call the transfer_ownership function from the old owner
    let coords = Vec2 { x: 20, y: 21 };
    creation_dispatcher.create_quasar(coords);
}
