use dojo_starter::models::owner::Owner;
use dojo_starter::models::mass::Mass;
use dojo_starter::models::vec2::Vec2;
use dojo_starter::models::dust_balance::DustBalance;
use dojo_starter::models::dust_accretion::DustAccretion;
use dojo_starter::models::dust_emission::DustEmission;
use dojo_starter::models::orbit::Orbit;
use dojo_starter::utils::dust_farm::{calculate_ARPS, get_expected_dust_increase};

use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_contract_address, set_account_contract_address, set_block_timestamp}
};
use starknet::contract_address_const;

use dojo_starter::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
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
    let coords = Vec2 { x: 100, y: 100 };
    let galaxy_id = setup_dust_pool(world, coords, sender_owner);

    let star_mass = 200;
    let star_id = spawn_star(world, sender_owner, coords, star_mass);
    let star_id_two = spawn_star(world, sender_owner, coords, star_mass);
    let star_id_three = spawn_star(world, sender_owner, coords, star_mass);
    add_to_dust_pool(world, dust_dispatcher, galaxy_id, star_id);
    add_to_dust_pool(world, dust_dispatcher, galaxy_id, star_id_two);
    add_to_dust_pool(world, dust_dispatcher, galaxy_id, star_id_three);

    let non_member_star_id = spawn_star(world, sender_owner, coords, star_mass);

    (world, star_id, non_member_star_id, galaxy_id, sender_owner, dust_dispatcher)
}

fn setup_dust_pool(world: IWorldDispatcher, coords: Vec2, owner: ContractAddress) -> u32 {
    let emission_rate = 1_000_000_000_000_000; // 0.001 dust per second
    let galaxy_mass = 5_000_000;
    let galaxy_id = spawn_galaxy(world, owner, coords, emission_rate, galaxy_mass);

    return galaxy_id;
}

fn add_to_dust_pool(
    world: IWorldDispatcher, dust_dispatcher: IDustSystemsDispatcher, pool_id: u32, star_id: u32
) {
    let pool_mass = get!(world, pool_id, Mass);
    let star_mass = get!(world, star_id, Mass);

    set!(
        world,
        (
            Orbit { entity: star_id, orbit_center: pool_id },
            Mass {
                entity: pool_id,
                mass: pool_mass.mass,
                orbit_mass: pool_mass.orbit_mass + star_mass.mass
            }
        )
    );

    dust_dispatcher.enter_dust_pool(star_id, pool_id);
}


#[test]
#[available_gas(3000000000000)]
fn test_claim_dust_valid() {
    let (world, star_id, _, galaxy_id, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_dust_balance = get!(world, star_id, DustBalance);

    let cur_ts = get_block_timestamp();
    let new_ts = cur_ts + 10;

    let expected_claimable_dust = get_expected_dust_increase(
        new_ts,
        get!(world, star_id, Mass),
        get!(world, galaxy_id, Mass),
        get!(world, star_id, DustAccretion),
        get!(world, galaxy_id, DustEmission)
    );
    let expected_balance = old_dust_balance.balance + expected_claimable_dust;

    set_block_timestamp(new_ts);

    dust_dispatcher.update_emission(galaxy_id);
    dust_dispatcher.claim_dust(star_id);

    let new_dust_balance = get!(world, star_id, DustBalance);

    assert(new_dust_balance.balance == expected_balance, 'balance incorrect');
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
