use core::array::{ArrayTrait, SpanTrait};
use dojo_starter::models::{
    loosh_balance, basal_attributes, incubation, owner, position, mass, travel_action, vec2,
    dust_balance, dust_emission, dust_accretion, dust_cloud, orbit, loosh_sink, cosmic_body,
    dust_pool, orbital_mass
};
use dojo::utils::test::{spawn_test_world};
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

use starknet::{ContractAddress, contract_address_const};

fn spawn_world() -> IWorldDispatcher {
    let mut models = array![
        loosh_balance::loosh_balance::TEST_CLASS_HASH,
        basal_attributes::basal_attributes::TEST_CLASS_HASH,
        incubation::incubation::TEST_CLASS_HASH,
        owner::owner::TEST_CLASS_HASH,
        position::position::TEST_CLASS_HASH,
        position::orbit_center_at_position::TEST_CLASS_HASH,
        mass::mass::TEST_CLASS_HASH,
        orbital_mass::orbital_mass::TEST_CLASS_HASH,
        travel_action::travel_action::TEST_CLASS_HASH,
        dust_balance::dust_balance::TEST_CLASS_HASH,
        dust_emission::dust_emission::TEST_CLASS_HASH,
        dust_accretion::dust_accretion::TEST_CLASS_HASH,
        dust_pool::dust_pool::TEST_CLASS_HASH,
        dust_cloud::dust_cloud::TEST_CLASS_HASH,
        orbit::orbit::TEST_CLASS_HASH,
        cosmic_body::cosmic_body::TEST_CLASS_HASH,
    ];

    let world = spawn_test_world(["dojo_starter"].span(), models.span());

    world.uuid();

    return world;
}

