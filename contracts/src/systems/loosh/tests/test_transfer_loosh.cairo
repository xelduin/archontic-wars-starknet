use starknet::{ContractAddress, testing::{set_contract_address, set_account_contract_address}};
use starknet::contract_address_const;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::utils::testing::{world::spawn_world};

use astraplani::models::owner::Owner;
use astraplani::models::mass::Mass;
use astraplani::models::vec2::Vec2;
use astraplani::models::loosh_balance::LooshBalance;

use astraplani::systems::loosh::contracts::loosh_systems::{
    loosh_systems, ILooshSystemsDispatcher, ILooshSystemsDispatcherTrait
};

fn setup() -> (WorldStorage, ContractAddress, ContractAddress, ILooshSystemsDispatcher) {
    let mut world = spawn_world();

    let (loosh_address, _) = world.dns(@"loosh_systems").unwrap();
    let loosh_dispatcher = ILooshSystemsDispatcher { contract_address: loosh_address };

    let sender_owner = contract_address_const::<'sender_owner'>();
    let receiver_owner = contract_address_const::<'receiver_owner'>();

    let loosh_balance = LooshBalance { address: sender_owner, balance: 1000 };

    world.write_model_test(@loosh_balance);

    (world, sender_owner, receiver_owner, loosh_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_transfer_loosh() {
    let (world, sender_owner, receiver_owner, loosh_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_sender_balance = get!(world, sender_owner, LooshBalance);
    let old_receiver_balance = get!(world, receiver_owner, LooshBalance);

    let loosh_amount = old_sender_balance.balance / 2;
    loosh_dispatcher.transfer_loosh(receiver_owner, loosh_amount);

    let new_sender_balance = get!(world, sender_owner, LooshBalance);
    assert(
        new_sender_balance.balance == old_sender_balance.balance - loosh_amount,
        'sender loosh not decreased'
    );

    let new_receiver_balance = get!(world, receiver_owner, LooshBalance);
    assert(
        new_receiver_balance.balance == old_receiver_balance.balance + loosh_amount,
        'receiver loosh not increased'
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

    let loosh_amount = old_sender_balance.balance + 1;
    loosh_dispatcher.transfer_loosh(receiver_owner, loosh_amount);
}
