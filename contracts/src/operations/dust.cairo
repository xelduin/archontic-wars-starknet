use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::validators::dust::assert_can_carry_dust;
use astraplani::validators::dust::assert_has_dust_balance;

use astraplani::models::dust_balance::DustBalance;

fn transfer_dust_balance(world: WorldStorage, sender_id: u32, receiver_id: u32, amount: u128) {
    decrease_dust_balance(sender_id, amount);    
    increase_dust_balance(receiver_id, amount);
}

fn increase_dust_balance(world: WorldStorage, entity_id: u32, amount: u32) {
    assert_can_carry_dust(world, receiver_id, amount);

    let dust_balance : DustBalance = world.read_model(entity_id);    
    world.write_model(@Dust_Balance {..dust_balance, balance: dust_balance.balance + amount});
};

fn decrease_dust_balance(world: WorldStorage, entity_id: u32, amount: u32) {
    assert_has_dust_balance(world, sender_id, amount);
    
    let dust_balance : DustBalance = world.read_model(entity_id);
    world.write_model(@Dust_Balance {..dust_balance, balance: dust_balance.balance - amount});
};