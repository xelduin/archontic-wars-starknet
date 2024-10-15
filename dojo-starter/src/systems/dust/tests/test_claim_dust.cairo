use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::Vec2;
use dojo_starter::models::dust_balance::DustBalance;
use dojo_starter::models::dust_emission::DustEmission;
use dojo_starter::models::orbit::Orbit;
use dojo_starter::utils::dust_farm::{calculate_ARPS};

use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_contract_address, set_account_contract_address, set_block_timestamp}
};
use starknet::contract_address_const;

use dojo_starter::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

use dojo_starter::systems::movement::contracts::movement_systems::{
    movement_systems, IMovementSystemsDispatcher, IMovementSystemsDispatcherTrait
};


use dojo_starter::utils::testing::{
    world::spawn_world, spawners::spawn_galaxy, spawners::spawn_star,
    spawners::spawn_asteroid_cluster
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (IWorldDispatcher, u32, u32, u32, ContractAddress, IDustSystemsDispatcher) {
    let world = spawn_world();

    let dust_address = world
        .deploy_contract('salt', dust_systems::TEST_CLASS_HASH.try_into().unwrap());
    let dust_dispatcher = IDustSystemsDispatcher { contract_address: dust_address };

    world.grant_writer(dojo::utils::bytearray_hash(@"dojo_starter"), dust_address);

    // Accounts
    let sender_owner = contract_address_const::<'sender_owner'>();

    // SET UP DUST POOL
    let emission_rate = 1_000_000_000_000_000; // 0.001 dust per second
    let coords = Vec2 { x: 100, y: 100 };
    let galaxy_id = spawn_galaxy(world, sender_owner, coords, emission_rate);
    let star_mass = 200;
    let star_id = spawn_star(world, sender_owner, coords, star_mass);
    let non_member_star_id = spawn_star(world, sender_owner, coords, star_mass);

    println!(
        "galaxy_id: {} \n
        star_id: {} \n
        non_member_star_id: {} \n
        ",
        galaxy_id,
        star_id,
        non_member_star_id
    );

    set!(
        world,
        (
            Orbit { entity: star_id, orbit_center: galaxy_id },
            Mass { entity: galaxy_id, mass: 5000, orbit_mass: 600 }
        )
    );

    dust_dispatcher.enter_dust_pool(star_id, galaxy_id);

    (world, star_id, non_member_star_id, galaxy_id, sender_owner, dust_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_claim_dust_valid() {
    let (world, star_id, _, galaxy_id, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_dust_balance = get!(world, star_id, DustBalance);

    let cur_ts = get_block_timestamp();

    set_block_timestamp(cur_ts + 10);

    dust_dispatcher.update_emission(galaxy_id);
    dust_dispatcher.claim_dust(star_id);

    let new_dust_balance = get!(world, star_id, DustBalance);

    assert(new_dust_balance.balance > old_dust_balance.balance, 'balance hasnt incresed');
}


#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in a pool', 'ENTRYPOINT_FAILED'))]
fn test_claim_from_non_member() {
    let (_, _, non_member_star_id, galaxy_id, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let cur_ts = get_block_timestamp();

    set_block_timestamp(cur_ts + 10);

    dust_dispatcher.update_emission(galaxy_id);
    dust_dispatcher.claim_dust(non_member_star_id);
}
