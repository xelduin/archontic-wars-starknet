#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustValueConfig {
    #[key]
    pub config_id: u32,
    pub mass_to_dust: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustEmissionConfig {
    #[key]
    pub config_id: u32,
    pub base_dust_emission: u128,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct HarvestTimeConfig {
    #[key]
    pub config_id: u32,
    pub min_harvest_time: u64,
    pub base_harvest_time: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BaseCosmicBodyMassConfig {
    #[key]
    pub config_id: u32,
    pub base_star_mass: u64,
    pub base_quasar_mass: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct MinOrbitCenterMassConfig {
    #[key]
    pub config_id: u32,
    pub min_mass_multiplier: u64,
}


#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct MaxCosmicBodyMassConfig {
    #[key]
    pub config_id: u32,
    pub max_asteroid_cluster_mass: u64,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LooshCostConfig {
    #[key]
    pub config_id: u32,
    pub base_travel_cost: u128,
    pub base_creation_cost: u128
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TravelSpeedConfig {
    #[key]
    pub config_id: u32,
    pub base_travel_speed: u64,
}

use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct AdminConfig {
    #[key]
    pub config_id: u32,
    pub admin_address: ContractAddress,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct IncubationTimeConfig {
    #[key]
    pub config_id: u32,
    pub base_incubation_time: u64,
}
