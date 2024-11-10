use astraplani::models::owner::Owner;
use astraplani::models::mass::Mass;
use astraplani::models::vec2::Vec2;
use astraplani::models::dust_balance::DustBalance;
use astraplani::models::dust_accretion::DustAccretion;
use astraplani::models::dust_emission::DustEmission;
use astraplani::models::dust_pool::DustPool;
use astraplani::models::orbit::Orbit;
use astraplani::models::basal_attributes::{
    BasalAttributes, BasalAttributesType, BasalAttributesImpl
};
use astraplani::models::dust_cloud::DustCloud;

use astraplani::utils::dust_farm::{
    calculate_ARPS, get_expected_dust_increase, get_expected_claimable_dust_for_star
};

use starknet::{
    ContractAddress, get_block_timestamp,
    testing::{set_contract_address, set_account_contract_address, set_block_timestamp}
};
use starknet::contract_address_const;

use astraplani::systems::dust::contracts::dust_systems::{
    dust_systems, IDustSystemsDispatcher, IDustSystemsDispatcherTrait
};

use astraplani::utils::testing::{
    world::spawn_world, spawners::spawn_quasar, spawners::spawn_star, dust_pool::add_to_dust_pool
};

use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

// Mock setup for the test
fn setup() -> (IWorldDispatcher, u32, u32, u32, ContractAddress, IDustSystemsDispatcher) {
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
    add_to_dust_pool(world, dust_dispatcher, quasar_id, star_id);
    set!(world, (BasalAttributes { entity: star_id, attributes: 20 }));

    let filler_star_one = spawn_star(world, sender_owner, coords, quasar_id, star_mass);
    let filler_star_two = spawn_star(world, sender_owner, coords, quasar_id, star_mass);
    add_to_dust_pool(world, dust_dispatcher, quasar_id, filler_star_one);
    add_to_dust_pool(world, dust_dispatcher, quasar_id, filler_star_two);

    let non_member_star_id = spawn_star(world, sender_owner, coords, quasar_id, star_mass);

    (world, star_id, non_member_star_id, quasar_id, sender_owner, dust_dispatcher)
}

#[test]
#[available_gas(3000000000000)]
fn test_claim_dust_valid() {
    let (world, star_id, _, quasar_id, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let old_dust_balance = get!(world, star_id, DustBalance);

    let cur_ts = get_block_timestamp();
    let new_ts = cur_ts + 10;

    let star_attributes = get!(world, star_id, BasalAttributes);
    let star_sense = star_attributes.get_attribute_value(BasalAttributesType::Sense);
    let expected_claimable_dust = get_expected_claimable_dust_for_star(
        new_ts,
        get!(world, star_id, Mass),
        get!(world, quasar_id, DustPool).total_mass,
        get!(world, star_id, DustAccretion),
        get!(world, quasar_id, DustEmission),
        star_sense
    );
    let expected_balance = old_dust_balance.balance + expected_claimable_dust;

    set_block_timestamp(new_ts);

    //dust_dispatcher.update_emission(quasar_id);
    dust_dispatcher.claim_dust(star_id);

    //let dust_cloud = get!(world, (100, 100, quasar_id), DustCloud);

    let new_dust_balance = get!(world, star_id, DustBalance);

    assert(new_dust_balance.balance == expected_balance, 'balance incorrect');
}


#[test]
#[available_gas(3000000000000)]
#[should_panic(expected: ('not in dust pool', 'ENTRYPOINT_FAILED'))]
fn test_claim_from_non_member() {
    let (_, _, non_member_star_id, _, sender_owner, dust_dispatcher) = setup();

    set_contract_address(sender_owner);
    set_account_contract_address(sender_owner);

    let cur_ts = get_block_timestamp();

    set_block_timestamp(cur_ts + 10);

    dust_dispatcher.claim_dust(non_member_star_id);
}
