use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_contract_address, set_account_contract_address, set_block_timestamp}
};
use starknet::contract_address_const;

use dojo::world::{WorldStorage, WorldStorageTrait};
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::event::EventStorage;
use dojo::world::IWorldDispatcherTrait;

use astraplani::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};
use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_quasar, spawners::spawn_star, dust_pool::add_to_dust_pool
};
use astraplani::models::owner::Owner;
use astraplani::models::mass::Mass;
use astraplani::models::vec2::Vec2;
use astraplani::models::dust_balance::DustBalance;
use astraplani::models::dust_accretion::DustAccretion;
use astraplani::models::dust_emission::DustEmission;
use astraplani::models::dust_pool::DustPool;
use astraplani::models::orbit::Orbit;
use astraplani::utils::dust_farm::{calculate_ARPS};

fn setup() -> (IWorldDispatcher, u32, u32, ContractAddress, IDustSystemsDispatcher) {
    let world = spawn_world();

    let dust_address = world
        .deploy_contract('salt', dust_systems::TEST_CLASS_HASH.try_into().unwrap());
    let dust_dispatcher = IDustSystemsDispatcher { contract_address: dust_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"astraplani"), dust_address);

    // Accounts
    let sender_owner = contract_address_const::<'sender_owner'>();

    // SET UP DUST POOL
    let coords = Vec2 { x: 100, y: 100 };

    let emission_rate = 1_000_000_000_000_000; // 0.001 dust per second
    let quasar_mass = 5_000_000;
    let quasar_id = spawn_quasar(world, sender_owner, coords, emission_rate, quasar_mass);

    let star_mass = 200;
    let star_id = spawn_star(world, sender_owner, coords, quasar_id, star_mass);
    let star_id_two = spawn_star(world, sender_owner, coords, quasar_id, star_mass);
    let star_id_three = spawn_star(world, sender_owner, coords, quasar_id, star_mass);
    add_to_dust_pool(world, dust_dispatcher, quasar_id, star_id);
    add_to_dust_pool(world, dust_dispatcher, quasar_id, star_id_two);
    add_to_dust_pool(world, dust_dispatcher, quasar_id, star_id_three);

    (world, star_id, quasar_id, sender_owner, dust_dispatcher)
}


#[test]
#[available_gas(3000000000000)]
fn test_update_emission_valid() {
    let (world, _, quasar_id, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_pool_emission = get!(world, quasar_id, DustEmission);

    let cur_ts = get_block_timestamp();
    let new_ts = cur_ts + 10;

    let quasar_pool = get!(world, quasar_id, DustPool);
    let expected_ARPS = calculate_ARPS(new_ts, old_pool_emission, quasar_pool.total_mass);

    set_block_timestamp(new_ts);

    dust_dispatcher.update_emission(quasar_id);

    let new_pool_emission = get!(world, quasar_id, DustEmission);

    assert(new_pool_emission.ARPS == expected_ARPS, 'ARPS not updated');
    assert(new_pool_emission.last_update_ts == new_ts, 'last_update_ts not updated');
}


#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('no emission', 'ENTRYPOINT_FAILED'))]
fn test_update_emission_non_pool() {
    let (_, star_id, _, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let cur_ts = get_block_timestamp();

    set_block_timestamp(cur_ts + 10);

    dust_dispatcher.update_emission(star_id);
}
