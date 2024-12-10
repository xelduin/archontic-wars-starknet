use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage, ModelStorageTest};
use dojo::world::WorldStorageTrait;
use dojo::world::IWorldDispatcherTrait;
use dojo_cairo_test::{
    spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, ContractDef,
    WorldStorageTestTrait
};
use core::array::{ArrayTrait, SpanTrait};

use astraplani::models::loosh_balance::{LooshBalance, m_LooshBalance};
use astraplani::models::basal_attributes::{BasalAttributes, m_BasalAttributes};
use astraplani::models::incubation::{Incubation, m_Incubation};
use astraplani::models::owner::{Owner, m_Owner};
use astraplani::models::position::{Position, m_Position};
use astraplani::models::position::{OrbitCenterAtPosition, m_OrbitCenterAtPosition};
use astraplani::models::mass::{Mass, m_Mass};
use astraplani::models::orbital_mass::{OrbitalMass, m_OrbitalMass};
use astraplani::models::travel_action::{TravelAction, m_TravelAction};
use astraplani::models::dust_balance::{DustBalance, m_DustBalance};
use astraplani::models::dust_emission::{DustEmission, m_DustEmission};
use astraplani::models::dust_accretion::{DustAccretion, m_DustAccretion};
use astraplani::models::dust_pool::{DustPool, m_DustPool};
use astraplani::models::dust_cloud::{DustCloud, m_DustCloud};
use astraplani::models::orbit::{Orbit, m_Orbit};
use astraplani::models::cosmic_body::{CosmicBody, m_CosmicBody};
use astraplani::models::harvest_action::{HarvestAction, m_HarvestAction};
use astraplani::models::config::{AdminConfig, m_AdminConfig};
use astraplani::models::config::{DustValueConfig, m_DustValueConfig};
use astraplani::models::config::{DustEmissionConfig, m_DustEmissionConfig};
use astraplani::models::config::{HarvestTimeConfig, m_HarvestTimeConfig};
use astraplani::models::config::{BaseCosmicBodyMassConfig, m_BaseCosmicBodyMassConfig};
use astraplani::models::config::{MinOrbitCenterMassConfig, m_MinOrbitCenterMassConfig};
use astraplani::models::config::{MaxCosmicBodyMassConfig, m_MaxCosmicBodyMassConfig};
use astraplani::models::config::{LooshCostConfig, m_LooshCostConfig};
use astraplani::models::config::{TravelSpeedConfig, m_TravelSpeedConfig};
use astraplani::models::config::{IncubationTimeConfig, m_IncubationTimeConfig};

use astraplani::systems::authority::contracts::authority_systems::authority_systems::{
    OwnershipTransferred, e_OwnershipTransferred
};
use astraplani::systems::config::contracts::config_systems::config_systems::{
    AdminConfigUpdated, e_AdminConfigUpdated, 
    DustValueConfigUpdated, e_DustValueConfigUpdated, 
    DustEmissionConfigUpdated, e_DustEmissionConfigUpdated, 
    HarvestTimeConfigUpdated, e_HarvestTimeConfigUpdated, 
    BaseCosmicBodyMassConfigUpdated, e_BaseCosmicBodyMassConfigUpdated, 
    MinOrbitCenterMassConfigUpdated, e_MinOrbitCenterMassConfigUpdated, 
    MaxCosmicBodyMassConfigUpdated, e_MaxCosmicBodyMassConfigUpdated, 
    LooshCostConfigUpdated, e_LooshCostConfigUpdated, 
    TravelSpeedConfigUpdated, e_TravelSpeedConfigUpdated, 
    IncubationTimeConfigUpdated, e_IncubationTimeConfigUpdated, 
};
use astraplani::systems::creation::contracts::creation_systems::creation_systems::{
    QuasarCreated, e_QuasarCreated, ProtostarCreated, e_ProtostarCreated, AsteroidClusterCreated,
    e_AsteroidClusterCreated, StarFormed, e_StarFormed, AsteroidsFormed, e_AsteroidsFormed,
};
use astraplani::systems::dust::contracts::dust_systems::dust_systems::{
    DustPoolFormed, e_DustPoolFormed, DustClaimed, e_DustClaimed, DustConsumed, e_DustConsumed,
    DustPoolMassChange, e_DustPoolMassChange, DustCloudChange, e_DustCloudChange, ARPSUpdated,
    e_ARPSUpdated, DustPoolEntered, e_DustPoolEntered, DustPoolExited, e_DustPoolExited,
    HarvestActionBegan, e_HarvestActionBegan, HarvestActionEnded, e_HarvestActionEnded,
    HarvestActionCancelled, e_HarvestActionCancelled,
};
use astraplani::systems::loosh::contracts::loosh_systems::loosh_systems::{
    LooshTransferred, e_LooshTransferred, LooshBurned, e_LooshBurned, LooshMinted, e_LooshMinted,
};
use astraplani::systems::mass::contracts::mass_systems::mass_systems::{
    BodyMassChange, e_BodyMassChange
};
use astraplani::systems::movement::contracts::movement_systems::movement_systems::{
    TravelBegan, e_TravelBegan, TravelEnded, e_TravelEnded,
};

use astraplani::systems::authority::contracts::authority_systems::authority_systems;
use astraplani::systems::config::contracts::config_systems::config_systems;
use astraplani::systems::creation::contracts::creation_systems::creation_systems;
use astraplani::systems::dust::contracts::dust_systems::dust_systems;
use astraplani::systems::loosh::contracts::loosh_systems::loosh_systems;
use astraplani::systems::mass::contracts::mass_systems::mass_systems;
use astraplani::systems::movement::contracts::movement_systems::movement_systems;

use starknet::{ContractAddress, contract_address_const};

fn namespace_def() -> NamespaceDef {
    let ndef = NamespaceDef {
        namespace: "ns", resources: [
            //MODELS
            TestResource::Model(m_LooshBalance::TEST_CLASS_HASH),
            TestResource::Model(m_BasalAttributes::TEST_CLASS_HASH),
            TestResource::Model(m_Incubation::TEST_CLASS_HASH),
            TestResource::Model(m_Owner::TEST_CLASS_HASH),
            TestResource::Model(m_Position::TEST_CLASS_HASH),
            TestResource::Model(m_OrbitCenterAtPosition::TEST_CLASS_HASH),
            TestResource::Model(m_Mass::TEST_CLASS_HASH),
            TestResource::Model(m_OrbitalMass::TEST_CLASS_HASH),
            TestResource::Model(m_TravelAction::TEST_CLASS_HASH),
            TestResource::Model(m_DustBalance::TEST_CLASS_HASH),
            TestResource::Model(m_DustEmission::TEST_CLASS_HASH),
            TestResource::Model(m_DustAccretion::TEST_CLASS_HASH),
            TestResource::Model(m_DustPool::TEST_CLASS_HASH),
            TestResource::Model(m_DustCloud::TEST_CLASS_HASH),
            TestResource::Model(m_Orbit::TEST_CLASS_HASH),
            TestResource::Model(m_CosmicBody::TEST_CLASS_HASH),
            TestResource::Model(m_HarvestAction::TEST_CLASS_HASH),
            TestResource::Model(m_AdminConfig::TEST_CLASS_HASH),
            TestResource::Model(m_DustValueConfig::TEST_CLASS_HASH),
            TestResource::Model(m_DustEmissionConfig::TEST_CLASS_HASH),
            TestResource::Model(m_HarvestTimeConfig::TEST_CLASS_HASH),
            TestResource::Model(m_BaseCosmicBodyMassConfig::TEST_CLASS_HASH),
            TestResource::Model(m_MinOrbitCenterMassConfig::TEST_CLASS_HASH),
            TestResource::Model(m_MaxCosmicBodyMassConfig::TEST_CLASS_HASH),
            TestResource::Model(m_LooshCostConfig::TEST_CLASS_HASH),
            TestResource::Model(m_TravelSpeedConfig::TEST_CLASS_HASH),
            TestResource::Model(m_IncubationTimeConfig::TEST_CLASS_HASH),
            // EVENTS
            TestResource::Event(e_OwnershipTransferred::TEST_CLASS_HASH),
            TestResource::Event(e_AdminConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_DustValueConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_DustEmissionConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_HarvestTimeConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_BaseCosmicBodyMassConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_MinOrbitCenterMassConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_MaxCosmicBodyMassConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_LooshCostConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_TravelSpeedConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_IncubationTimeConfigUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_QuasarCreated::TEST_CLASS_HASH),
            TestResource::Event(e_ProtostarCreated::TEST_CLASS_HASH),
            TestResource::Event(e_AsteroidClusterCreated::TEST_CLASS_HASH),
            TestResource::Event(e_StarFormed::TEST_CLASS_HASH),
            TestResource::Event(e_AsteroidsFormed::TEST_CLASS_HASH),
            TestResource::Event(e_DustPoolFormed::TEST_CLASS_HASH),
            TestResource::Event(e_DustClaimed::TEST_CLASS_HASH),
            TestResource::Event(e_DustConsumed::TEST_CLASS_HASH),
            TestResource::Event(e_DustPoolMassChange::TEST_CLASS_HASH),
            TestResource::Event(e_DustCloudChange::TEST_CLASS_HASH),
            TestResource::Event(e_ARPSUpdated::TEST_CLASS_HASH),
            TestResource::Event(e_DustPoolEntered::TEST_CLASS_HASH),
            TestResource::Event(e_DustPoolExited::TEST_CLASS_HASH),
            TestResource::Event(e_HarvestActionBegan::TEST_CLASS_HASH),
            TestResource::Event(e_HarvestActionEnded::TEST_CLASS_HASH),
            TestResource::Event(e_HarvestActionCancelled::TEST_CLASS_HASH),
            TestResource::Event(e_LooshTransferred::TEST_CLASS_HASH),
            TestResource::Event(e_LooshBurned::TEST_CLASS_HASH),
            TestResource::Event(e_LooshMinted::TEST_CLASS_HASH),
            TestResource::Event(e_BodyMassChange::TEST_CLASS_HASH),
            TestResource::Event(e_TravelBegan::TEST_CLASS_HASH),
            TestResource::Event(e_TravelEnded::TEST_CLASS_HASH),
            // CONTRACTS
            TestResource::Contract(authority_systems::TEST_CLASS_HASH),
            TestResource::Contract(config_systems::TEST_CLASS_HASH),
            TestResource::Contract(creation_systems::TEST_CLASS_HASH),
            TestResource::Contract(dust_systems::TEST_CLASS_HASH),
            TestResource::Contract(loosh_systems::TEST_CLASS_HASH),
            TestResource::Contract(mass_systems::TEST_CLASS_HASH),
            TestResource::Contract(movement_systems::TEST_CLASS_HASH),
        ].span()
    };

    return ndef;
}

fn contract_defs() -> Span<ContractDef> {
    [
        ContractDefTrait::new(@"ns", @"authority_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
        ContractDefTrait::new(@"ns", @"config_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
        ContractDefTrait::new(@"ns", @"creation_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
        ContractDefTrait::new(@"ns", @"dust_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
        ContractDefTrait::new(@"ns", @"loosh_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
        ContractDefTrait::new(@"ns", @"mass_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
        ContractDefTrait::new(@"ns", @"movement_systems")
            .with_writer_of([dojo::utils::bytearray_hash(@"ns")].span()),
    ].span()
}

fn spawn_world() -> WorldStorage {
    let ndef = namespace_def();
    let mut world = spawn_test_world([ndef].span());

    world.sync_perms_and_inits(contract_defs());

    world.dispatcher.uuid();

    setup_config(world);

    return world;
}

use astraplani::constants::{
    ADMIN_CONFIG_ID, DUST_VALUE_CONFIG_ID, DUST_EMISSION_CONFIG_ID, LOOSH_COST_CONFIG_ID,
    HARVEST_TIME_CONFIG_ID, COSMIC_BODY_MASS_CONFIG_ID, TRAVEL_SPEED_CONFIG_ID,
    INCUBATION_TIME_CONFIG_ID
};

use astraplani::utils::testing::constants::{
    MASS_TO_DUST_CONVERSION, BASE_DUST_EMISSION_RATE, BASE_STAR_MASS, BASE_QUASAR_MASS,
    MAX_ASTEROID_CLUSTER_MASS, BASE_LOOSH_TRAVEL_COST, BASE_LOOSH_CREATION_COST,
    BASE_TRAVEL_SECONDS_PER_TILE, BASE_INCUBATION_TIME, MIN_HARVEST_SECONDS, BASE_HARVEST_SECONDS
};

fn setup_config(mut world: WorldStorage) {
    let dust_value_config = DustValueConfig {
        config_id: DUST_VALUE_CONFIG_ID, mass_to_dust: MASS_TO_DUST_CONVERSION
    };
    let dust_emission_config = DustEmissionConfig {
        config_id: DUST_EMISSION_CONFIG_ID, base_dust_emission: BASE_DUST_EMISSION_RATE
    };
    let base_cosmic_body_mass_config = BaseCosmicBodyMassConfig {
        config_id: COSMIC_BODY_MASS_CONFIG_ID,
        base_star_mass: BASE_STAR_MASS,
        base_quasar_mass: BASE_QUASAR_MASS
    };
    let max_cosmic_body_mass_config = MaxCosmicBodyMassConfig {
        config_id: COSMIC_BODY_MASS_CONFIG_ID, max_asteroid_cluster_mass: MAX_ASTEROID_CLUSTER_MASS
    }; //This needs to be joined with bsae_cosmic_body_config
    let loosh_cost_config = LooshCostConfig {
        config_id: LOOSH_COST_CONFIG_ID,
        base_travel_cost: BASE_LOOSH_TRAVEL_COST,
        base_creation_cost: BASE_LOOSH_CREATION_COST
    };
    let travel_speed_config = TravelSpeedConfig {
        config_id: TRAVEL_SPEED_CONFIG_ID, base_travel_speed: BASE_TRAVEL_SECONDS_PER_TILE
    };
    let harvest_time_config = HarvestTimeConfig {
        config_id: HARVEST_TIME_CONFIG_ID,
        min_harvest_time: MIN_HARVEST_SECONDS,
        base_harvest_time: BASE_HARVEST_SECONDS,
    };
    let incubation_time_config = IncubationTimeConfig {
        config_id: INCUBATION_TIME_CONFIG_ID, base_incubation_time: BASE_INCUBATION_TIME
    };

    world.write_model(@dust_value_config);
    world.write_model(@dust_emission_config);
    world.write_model(@base_cosmic_body_mass_config);
    world.write_model(@max_cosmic_body_mass_config);
    world.write_model(@loosh_cost_config);
    world.write_model(@travel_speed_config);
    world.write_model(@harvest_time_config);
    world.write_model(@incubation_time_config);
}
