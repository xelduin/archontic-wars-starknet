use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IConfigSystems<T> {
    fn set_admin_config(ref self: T, config_id: u32, admin_address: ContractAddress);
    fn set_dust_value_config(ref self: T, config_id: u32, mass_to_dust: u128);
    fn set_dust_emission_config(ref self: T, config_id: u32, base_dust_emission: u128);
    fn set_harvest_time(ref self: T, config_id: u32, min_harvest_time: u64, base_harvest_time: u64);
    fn set_base_cosmic_body_mass(
        ref self: T, config_id: u32, base_star_mass: u64, base_quasar_mass: u64
    );
    fn set_min_orbit_center_mass(ref self: T, config_id: u32, min_mass_multiplier: u64);
    fn set_max_cosmic_body_mass(ref self: T, config_id: u32, max_asteroid_cluster_mass: u64);
    fn set_loosh_cost(
        ref self: T, config_id: u32, base_travel_cost: u128, base_creation_cost: u128
    );
    fn set_travel_speed(ref self: T, config_id: u32, base_travel_speed: u64);
    fn set_incubation_time(ref self: T, config_id: u32, base_incubation_time: u64);
}

// Dojo decorator
#[dojo::contract]
mod config_systems {
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    use super::{IConfigSystems};
    use starknet::{ContractAddress, get_caller_address};

    use astraplani::constants::ADMIN_CONFIG_ID;

    use astraplani::models::config::AdminConfig;
    use astraplani::models::config::DustValueConfig;
    use astraplani::models::config::DustEmissionConfig;
    use astraplani::models::config::HarvestTimeConfig;
    use astraplani::models::config::BaseCosmicBodyMassConfig;
    use astraplani::models::config::MinOrbitCenterMassConfig;
    use astraplani::models::config::MaxCosmicBodyMassConfig;
    use astraplani::models::config::LooshCostConfig;
    use astraplani::models::config::TravelSpeedConfig;
    use astraplani::models::config::IncubationTimeConfig;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct AdminConfigUpdated {
        #[key]
        config_id: u32,
        admin_address: ContractAddress
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustValueConfigUpdated {
        #[key]
        config_id: u32,
        mass_to_dust: u128
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustEmissionConfigUpdated {
        #[key]
        config_id: u32,
        base_dust_emission: u128
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestTimeConfigUpdated {
        #[key]
        config_id: u32,
        min_harvest_time: u64,
        base_harvest_time: u64,
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct BaseCosmicBodyMassConfigUpdated {
        #[key]
        config_id: u32,
        base_star_mass: u64,
        base_quasar_mass: u64
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct MinOrbitCenterMassConfigUpdated {
        #[key]
        config_id: u32,
        min_mass_multiplier: u64
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct MaxCosmicBodyMassConfigUpdated {
        #[key]
        config_id: u32,
        max_asteroid_cluster_mass: u64
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct LooshCostConfigUpdated {
        #[key]
        config_id: u32,
        base_travel_cost: u128,
        base_creation_cost: u128
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct TravelSpeedConfigUpdated {
        #[key]
        config_id: u32,
        base_travel_speed: u64
    }
    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct IncubationTimeConfigUpdated {
        #[key]
        config_id: u32,
        base_incubation_time: u64
    }

    fn assert_caller_is_admin(mut world: WorldStorage) {
        let admin_config: AdminConfig = world.read_model(ADMIN_CONFIG_ID);
        if admin_config.admin_address != Zeroable::zero() {
            assert(starknet::get_caller_address() == admin_config.admin_address, 'not admin');
        }
    }


    #[abi(embed_v0)]
    impl ConfigSystemsImpl of IConfigSystems<ContractState> {
        fn set_admin_config(
            ref self: ContractState, config_id: u32, admin_address: ContractAddress
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(AdminConfig { config_id, admin_address }));
            world.emit_event(@(AdminConfigUpdated { config_id, admin_address }));
        }

        fn set_dust_value_config(ref self: ContractState, config_id: u32, mass_to_dust: u128) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(DustValueConfig { config_id, mass_to_dust }));
            world.emit_event(@(DustValueConfigUpdated { config_id, mass_to_dust }));
        }

        fn set_dust_emission_config(
            ref self: ContractState, config_id: u32, base_dust_emission: u128
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(DustEmissionConfig { config_id, base_dust_emission }));
            world.emit_event(@(DustEmissionConfigUpdated { config_id, base_dust_emission }));
        }

        fn set_harvest_time(
            ref self: ContractState, config_id: u32, min_harvest_time: u64, base_harvest_time: u64
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world
                .write_model(
                    @(HarvestTimeConfig { config_id, min_harvest_time, base_harvest_time })
                );
            world
                .emit_event(
                    @(HarvestTimeConfigUpdated { config_id, min_harvest_time, base_harvest_time })
                );
        }

        fn set_base_cosmic_body_mass(
            ref self: ContractState, config_id: u32, base_star_mass: u64, base_quasar_mass: u64
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world
                .write_model(
                    @(BaseCosmicBodyMassConfig { config_id, base_star_mass, base_quasar_mass })
                );
            world
                .emit_event(
                    @(BaseCosmicBodyMassConfigUpdated {
                        config_id, base_star_mass, base_quasar_mass
                    })
                );
        }

        fn set_min_orbit_center_mass(
            ref self: ContractState, config_id: u32, min_mass_multiplier: u64
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(MinOrbitCenterMassConfig { config_id, min_mass_multiplier }));
            world.emit_event(@(MinOrbitCenterMassConfigUpdated { config_id, min_mass_multiplier }));
        }

        fn set_max_cosmic_body_mass(
            ref self: ContractState, config_id: u32, max_asteroid_cluster_mass: u64
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(MaxCosmicBodyMassConfig { config_id, max_asteroid_cluster_mass }));
            world
                .emit_event(
                    @(MaxCosmicBodyMassConfigUpdated { config_id, max_asteroid_cluster_mass })
                );
        }

        fn set_loosh_cost(
            ref self: ContractState,
            config_id: u32,
            base_travel_cost: u128,
            base_creation_cost: u128
        ) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world
                .write_model(
                    @(LooshCostConfig { config_id, base_travel_cost, base_creation_cost })
                );
            world
                .emit_event(
                    @(LooshCostConfigUpdated { config_id, base_travel_cost, base_creation_cost })
                );
        }

        fn set_travel_speed(ref self: ContractState, config_id: u32, base_travel_speed: u64) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(TravelSpeedConfig { config_id, base_travel_speed }));
            world.emit_event(@(TravelSpeedConfigUpdated { config_id, base_travel_speed }));
        }

        fn set_incubation_time(ref self: ContractState, config_id: u32, base_incubation_time: u64) {
            let mut world = self.world(@"ns");

            assert_caller_is_admin(world);
            let mut world = self.world(@"ns");
            world.write_model(@(IncubationTimeConfig { config_id, base_incubation_time }));
            world.emit_event(@(IncubationTimeConfigUpdated { config_id, base_incubation_time }));
        }
    }
}
