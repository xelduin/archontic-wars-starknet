use starknet::{ContractAddress};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::models::pneuma_balance::PneumaBalance;

fn assert_has_pneuma_balance(mut world: WorldStorage, address: ContractAddress, amount: u128) {
    let pneuma_balance: PneumaBalance = world.read_model(address);

    assert(pneuma_balance.balance >= amount, 'insufficient pneuma');
}
