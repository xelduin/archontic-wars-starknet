use astraplani::models::{
    dust_emission::DustEmission, dust_accretion::DustAccretion, orbit::Orbit, mass::Mass
};


// Define the interface for the Dust system
#[starknet::interface]
trait IDustSystems<T> {
    fn claim_dust(ref self: T, body_id: u32);
    fn update_emission(ref self: T, body_id: u32);
    fn enter_dust_pool(ref self: T, body_id: u32, pool_id: u32);
    fn begin_dust_harvest(ref self: T, body_id: u32, harvest_amount: u128);
    fn end_dust_harvest(ref self: T, body_id: u32);
    fn cancel_dust_harvest(ref self: T, body_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod dust_systems {
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    use super::{IDustSystems};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use astraplani::utils::dust_farm::{
        calculate_ARPS, calculate_unclaimed_dust, get_harvest_end_ts
    };

    use astraplani::constants::DUST_EMISSION_CONFIG_ID;
    use astraplani::constants::DUST_VALUE_CONFIG_ID;

    use astraplani::models::config::DustEmissionConfig;
    use astraplani::models::config::DustValueConfig;

    use astraplani::models::dust_pool::DustPool;
    use astraplani::models::dust_balance::DustBalance;
    use astraplani::models::dust_accretion::DustAccretion;
    use astraplani::models::dust_emission::DustEmission;
    use astraplani::models::orbit::Orbit;
    use astraplani::models::owner::Owner;
    use astraplani::models::travel_action::TravelAction;
    use astraplani::models::harvest_action::HarvestAction;
    use astraplani::models::mass::Mass;
    use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use astraplani::models::basal_attributes::{
        BasalAttributes, BasalAttributesType, BasalAttributesImpl
    };
    use astraplani::models::dust_cloud::DustCloud;
    use astraplani::models::position::Position;
    use astraplani::models::vec2::Vec2;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustPoolFormed {
        #[key]
        body_id: u32,
        emission_rate: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustClaimed {
        #[key]
        body_id: u32,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustConsumed {
        #[key]
        body_id: u32,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustPoolMassChange {
        #[key]
        body_id: u32,
        old_mass: u64,
        new_mass: u64
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustCloudChange {
        #[key]
        coords: Vec2,
        old_dust_amount: u128,
        new_dust_amount: u128
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct ARPSUpdated {
        #[key]
        body_id: u32,
        updated_ARPS: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustPoolEntered {
        #[key]
        body_id: u32,
        pool_id: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct DustPoolExited {
        #[key]
        body_id: u32,
        pool_id: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestActionBegan {
        #[key]
        body_id: u32,
        cloud_coords: Vec2,
        amount: u128,
        harvest_end_ts: u64
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestActionEnded {
        #[key]
        body_id: u32,
        cloud_coords: Vec2,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestActionCancelled {
        #[key]
        body_id: u32,
        cloud_coords: Vec2,
    }

    #[abi(embed_v0)]
    impl DustSystemsImpl of IDustSystems<ContractState> {
        fn claim_dust(ref self: ContractState, body_id: u32) {
            let mut world = self.world(@"ns");
            //InternalDustSystemsImpl::claim_dust(world, body_id);
            InternalDustSystemsImpl::update_local_pool(world, body_id);
        }

        fn update_emission(ref self: ContractState, body_id: u32) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::update_emission(world, body_id);
        }

        fn enter_dust_pool(ref self: ContractState, body_id: u32, pool_id: u32) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::enter_dust_pool(world, body_id, pool_id);
        }

        fn begin_dust_harvest(ref self: ContractState, body_id: u32, harvest_amount: u128) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::begin_dust_harvest(world, body_id, harvest_amount);
        }
        fn end_dust_harvest(ref self: ContractState, body_id: u32) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::end_dust_harvest(world, body_id);
        }
        fn cancel_dust_harvest(ref self: ContractState, body_id: u32) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::cancel_dust_harvest(world, body_id);
        }
    }

    #[generate_trait]
    impl InternalDustSystemsImpl of InternalDustSystemsTrait {
        fn form_dust_pool(mut world: WorldStorage, body_id: u32) {
            let cosmic_body_type : CosmicBody = world.read_model(body_id);
            assert(cosmic_body_type.body_type == CosmicBodyType::Quasar, 'must be quasar');

            let dust_emission_config : DustEmissionConfig = world.read_model(DUST_EMISSION_CONFIG_ID);
            let emission_rate = dust_emission_config.base_dust_emission;

            let current_ts = get_block_timestamp();

            world.write_model(
                @(
                    DustEmission {
                        entity: body_id, emission_rate, ARPS: 0, last_update_ts: current_ts
                    },
                )
            );
            world.emit_event(@(DustPoolFormed { body_id, emission_rate }));
        }

        fn enter_dust_pool(mut world: WorldStorage, body_id: u32, pool_id: u32) {
            let child_orbit : Orbit = world.read_model(body_id);
            assert(child_orbit.orbit_center == pool_id, 'not in orbit');

            let child_dust_accretion : DustAccretion = world.read_model(body_id);
            assert(child_dust_accretion.in_dust_pool == false, 'already in dust pool');

            let child_mass : Mass = world.read_model(body_id);
            let parent_mass : Mass = world.read_model(pool_id);
            let parent_emission : DustEmission = world.read_model(pool_id);

            let min_allowed_mass = child_mass.mass * 10;
            assert(parent_mass.mass >= min_allowed_mass, 'pool mass too low');

            Self::update_emission(world, pool_id);
            Self::increase_total_pool_mass(world, pool_id, child_mass.mass);

            world.write_model(@(DustAccretion {
                    entity: body_id,
                    debt: parent_emission.ARPS * child_mass.mass.try_into().unwrap(),
                    in_dust_pool: true
                })
            );
            world.emit_event(@(DustPoolEntered { body_id, pool_id }));
        }

        fn exit_dust_pool(mut world: WorldStorage, body_id: u32) {
            let body_orbit : Orbit = world.read_model(body_id);
            let pool_id = body_orbit.orbit_center;

            let body_dust_accretion : DustAccretion = world.read_model(body_id);
            assert(body_dust_accretion.in_dust_pool, 'not in dust pool');

            let body_mass : Mass = world.read_model(body_id);

            Self::update_emission(world, body_id);
            Self::claim_dust(world, body_id);
            Self::decrease_total_pool_mass(world, pool_id, body_mass.mass);

            world.erase_model(@(body_dust_accretion));
            world.emit_event(@(DustPoolExited { body_id, pool_id }));
        }

        fn update_emission(mut world: WorldStorage, pool_id: u32) {
            let dust_emission : DustEmission = world.read_model(pool_id);
            assert(dust_emission.emission_rate > 0, 'no emission');

            let pool_mass : DustPool = world.read_model(pool_id);
            if pool_mass.total_mass == 0 {
                return;
            };

            let current_ts = get_block_timestamp();

            let updated_ARPS = calculate_ARPS(current_ts, dust_emission, pool_mass.total_mass);

            world.write_model(@(DustEmission {
                    entity: pool_id,
                    emission_rate: dust_emission.emission_rate,
                    ARPS: updated_ARPS,
                    last_update_ts: current_ts,
                })
            );
            world.emit_event(@(ARPSUpdated { body_id: pool_id, updated_ARPS }));
        }

        fn update_local_pool(mut world: WorldStorage, body_id: u32) {
            let body_accretion : DustAccretion = world.read_model(body_id);
            assert(body_accretion.in_dust_pool, 'not in dust pool');

            let body_orbit : Orbit = world.read_model(body_id);
            let pool_id = body_orbit.orbit_center;
            Self::update_emission(world, pool_id);

            let pool_emission : DustEmission = world.read_model(pool_id);
            let body_mass : Mass = world.read_model(body_id);
            let unclaimed_pool_dust = calculate_unclaimed_dust(
                pool_emission, body_accretion, body_mass
            );

            let body_attributes : BasalAttributes = world.read_model(body_id);
            let body_sense = body_attributes.get_attribute_value(BasalAttributesType::Sense);
            let body_unclaimed_dust = unclaimed_pool_dust * body_sense.try_into().unwrap() / 100;

            let current_dust : DustBalance = world.read_model(body_id);
            let new_dust_balance = current_dust.balance + body_unclaimed_dust;
            let dust_remainder = unclaimed_pool_dust - body_unclaimed_dust;
            let body_position : Position = world.read_model(body_id);
            let dust_cloud : DustCloud = world.read_model((body_position.vec.x, body_position.vec.y, pool_id));
            let dust_cloud_balance = dust_cloud.dust_balance;
            world.write_model(@(
                    DustBalance { entity: body_id, balance: new_dust_balance },
                    DustAccretion {
                        entity: body_id,
                        debt: body_accretion.debt + unclaimed_pool_dust,
                        in_dust_pool: true
                    },
                    DustCloud {
                        x: body_position.vec.x,
                        y: body_position.vec.y,
                        orbit_center: pool_id,
                        dust_balance: dust_cloud_balance + dust_remainder
                    }
                )
            );
            world.emit_event(@(
                    DustClaimed { body_id, amount: body_unclaimed_dust },
                    DustCloudChange {
                        coords: body_position.vec,
                        old_dust_amount: dust_cloud_balance,
                        new_dust_amount: dust_cloud_balance + dust_remainder
                    }
                )
            );
        }

        fn update_pool_member(mut world: WorldStorage, body_id: u32, old_mass: u64, new_mass: u64) {
            assert(old_mass != new_mass, 'no mass change');

            let body_accretion : DustAccretion = world.read_model(body_id);
            assert(body_accretion.in_dust_pool, 'not in dust pool');

            let body_orbit : Orbit = world.read_model(body_id);
            let pool_id = body_orbit.orbit_center;
            let pool_emission : DustEmission = world.read_model(pool_id);
            assert(pool_emission.emission_rate > 0, 'invalid pool id');

            Self::update_emission(world, pool_id);
            Self::claim_dust(world, body_id);

            if old_mass > new_mass {
                Self::decrease_total_pool_mass(world, pool_id, old_mass - new_mass);
            } else {
                Self::increase_total_pool_mass(world, pool_id, new_mass - old_mass);
            }
        }

        fn increase_total_pool_mass(mut world: WorldStorage, pool_id: u32, mass: u64) {
            let dust_pool : DustPool = world.read_model(pool_id);
            let pool_mass = dust_pool.total_mass;
            world.write_model(@(DustPool { entity: pool_id, total_mass: pool_mass + mass }));
            world.emit_event(@(DustPoolMassChange {
                    body_id: pool_id, old_mass: pool_mass, new_mass: pool_mass + mass
                })
            );
        }

        fn decrease_total_pool_mass(mut world: WorldStorage, pool_id: u32, mass: u64) {
            let dust_pool : DustPool = world.read_model(pool_id);
            let pool_mass = dust_pool.total_mass;
            assert(pool_mass >= mass, 'pool mass too low');
            world.write_model(@(DustPool { entity: pool_id, total_mass: pool_mass - mass }));
            world.emit_event(@(DustPoolMassChange {
                    body_id: pool_id, old_mass: pool_mass, new_mass: pool_mass - mass
                })
            );
        }

        fn claim_dust(mut world: WorldStorage, body_id: u32) {
            let body_accretion : DustAccretion = world.read_model(body_id);
            assert(body_accretion.in_dust_pool, 'not in dust pool');

            let body_orbit : Orbit = world.read_model(body_id);
            let pool_id = body_orbit.orbit_center;
            let pool_emission : DustEmission = world.read_model(pool_id);
            let body_mass : Mass = world.read_model(body_id);
            let unclaimed_dust = calculate_unclaimed_dust(pool_emission, body_accretion, body_mass);

            let current_dust : DustBalance = world.read_model(body_id);
            let new_dust_balance = current_dust.balance + unclaimed_dust;

            world.write_model(@(
                    DustBalance { entity: body_id, balance: new_dust_balance },
                    DustAccretion { entity: body_id, debt: new_dust_balance, in_dust_pool: true }
                )
            );
            world.emit_event(@(DustClaimed { body_id, amount: unclaimed_dust }));
        }

        fn consume_dust(mut world: WorldStorage, body_id: u32, amount: u128) {
            let dust_balance : DustBalance = world.read_model(body_id);
            assert(dust_balance.balance >= amount, 'insufficient dust');

            let new_dust_balance = dust_balance.balance - amount;

            world.write_model(@(DustBalance { entity: body_id, balance: new_dust_balance }));
            world.emit_event(@(DustConsumed { body_id, amount }));
        }

        fn begin_dust_harvest(mut world: WorldStorage, body_id: u32, harvest_amount: u128) {
            let caller = get_caller_address();
            let owner : Owner = world.read_model(body_id);
            assert(caller == owner.address, 'not owner');

            let body_type : CosmicBody = world.read_model(body_id);
            assert(body_type.body_type == CosmicBodyType::AsteroidCluster, 'invalid body type');

            let body_position : Position = world.read_model(body_id);
            let body_orbit : Orbit = world.read_model(body_id);
            let dust_cloud : DustCloud = world.read_model((body_position.vec.x, body_position.vec.y, body_orbit.orbit_center));
            assert(dust_cloud.dust_balance >= harvest_amount, 'not enough dust');

            let body_mass : Mass = world.read_model(body_id)
            let dust_value_config : DustValueConfig = world.read_model(DUST_VALUE_CONFIG_ID);
            let mass_to_dust = dust_value_config.mass_to_dust;
            let harvest_capacity: u128 = body_mass.mass.try_into().unwrap() * mass_to_dust;
            assert(harvest_capacity >= harvest_amount, 'harvest amount too high');

            // CHECK FOR ACTIONS
            let harvest_action : HarvestAction = world.read_model(body_id);
            assert(harvest_action.end_ts == 0, 'entity already harvesting');
            let travel_action : TravelAction = world.read_model(body_id);
            assert(travel_action.arrival_ts == 0, 'cannot harvest while travelling');

            let cur_ts = get_block_timestamp();
            let end_ts = get_harvest_end_ts(world, cur_ts, harvest_amount, body_mass.mass);

            world.write_model(@(HarvestAction { entity: body_id, start_ts: cur_ts, end_ts, harvest_amount })
            );
            world.emit_event(@(HarvestActionBegan {
                    body_id,
                    cloud_coords: body_position.vec,
                    amount: harvest_amount,
                    harvest_end_ts: end_ts
                })
            );
        }

        fn end_dust_harvest(mut world: WorldStorage, body_id: u32) {
            let caller = get_caller_address();
            let owner : Owner = world.read_model(body_id);
            assert(caller == owner.address, 'not owner');

            let body_position : Position = world.read_model(body_id);
            let body_orbit : Orbit = world.read_model(body_id);
            let dust_cloud : DustCloud = world.read_model((body_position.vec.x, body_position.vec.y, body_orbit.orbit_center));

            let cur_ts = get_block_timestamp();
            let harvest_action : HarvestAction = world.read_model(body_id);
            assert(harvest_action.end_ts != 0, 'not harvesting');
            assert(cur_ts >= harvest_action.end_ts, 'harvest still underway');

            world.erase_model(@(harvest_action));

            let body_dust_balance : DustBalance = world.read_model(body_id);
            let harvested_dust = if harvest_action.harvest_amount > dust_cloud.dust_balance {
                dust_cloud.dust_balance
            } else {
                harvest_action.harvest_amount
            };

            world.write_model(@(
                    DustBalance {
                        entity: body_id, balance: body_dust_balance.balance + harvested_dust
                    },
                    DustCloud {
                        x: body_position.vec.x,
                        y: body_position.vec.y,
                        orbit_center: body_orbit.orbit_center,
                        dust_balance: dust_cloud.dust_balance - harvested_dust
                    }
                )
            );
            world.emit_event(@(
                    HarvestActionEnded {
                        body_id, amount: harvested_dust, cloud_coords: body_position.vec
                    },
                    DustCloudChange {
                        coords: body_position.vec,
                        old_dust_amount: dust_cloud.dust_balance,
                        new_dust_amount: dust_cloud.dust_balance + harvested_dust
                    }
                )
            );
        }

        fn cancel_dust_harvest(mut world: WorldStorage, body_id: u32) {
            let caller = get_caller_address();
            let owner : Owner = world.read_model(body_id);
            assert(caller == owner.address, 'not owner');

            let harvest_action : HarvestAction = world.read_model(body_id);
            assert(harvest_action.end_ts != 0, 'not harvesting');

            let body_position : Position = world.read_model(body_id);

            world.erase_model(@(harvest_action));
            world.emit_event(@(HarvestActionCancelled { body_id, cloud_coords: body_position.vec }));
        }
    }
}

