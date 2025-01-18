use starknet::{ContractAddress};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::models::dust_balance::DustBalance;
use astraplani::utils::dust::get_dust_carry_capacity;

fn assert_has_dust_balance(mut world: WorldStorage, entity_id: u32, amount: u128) {
    let dust_balance: DustBalance = world.read_model(entity_id);

    assert(dust_balance.balance >= amount, 'insufficient dust');
}


fn assert_can_carry_dust(mut world: WorldStorage, asteroid_id: u32, dust_amount: u128) {
    let dust_balance: DustBalance = world.read_model(entity_id);
    let max_carry_capacity = get_dust_carry_capacity(world, asteroid_id);

    assert(max_carry_capacity >= dust_balance.balance + dust_amount, 'too much dust');
}
