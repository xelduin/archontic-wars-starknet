use astraplani::models::{
    dust_emission::DustEmission, dust_accretion::DustAccretion, orbit::Orbit, mass::Mass
};


// Define the interface for the Dust system
#[dojo::interface]
trait IDustSystems {
    fn claim_dust(ref world: IWorldDispatcher, body_id: u32);
    fn update_emission(ref world: IWorldDispatcher, body_id: u32);
    fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32);
    fn begin_dust_harvest(ref world: IWorldDispatcher, body_id: u32, harvest_amount: u128);
    fn end_dust_harvest(ref world: IWorldDispatcher, body_id: u32);
    fn cancel_dust_harvest(ref world: IWorldDispatcher, body_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod dust_systems {
    use super::{IDustSystems};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use astraplani::utils::dust_farm::{
        calculate_ARPS, calculate_unclaimed_dust, get_harvest_end_ts
    };

    use astraplani::constants::DUST_EMISSION_CONFIG_ID;

    use astraplani::models::config::DustEmissionConfig;

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

    #[abi(embed_v0)]
    impl DustSystemsImpl of IDustSystems<ContractState> {
        fn claim_dust(ref world: IWorldDispatcher, body_id: u32) {
            //InternalDustSystemsImpl::claim_dust(world, body_id);
            InternalDustSystemsImpl::update_local_pool(world, body_id);
        }

        fn update_emission(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemsImpl::update_emission(world, body_id);
        }

        fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32) {
            InternalDustSystemsImpl::enter_dust_pool(world, body_id, pool_id);
        }

        fn begin_dust_harvest(ref world: IWorldDispatcher, body_id: u32, harvest_amount: u128) {
            InternalDustSystemsImpl::begin_dust_harvest(world, body_id, harvest_amount);
        }
        fn end_dust_harvest(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemsImpl::end_dust_harvest(world, body_id);
        }
        fn cancel_dust_harvest(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemsImpl::cancel_dust_harvest(world, body_id);
        }
    }

    #[generate_trait]
    impl InternalDustSystemsImpl of InternalDustSystemsTrait {
        fn form_dust_pool(world: IWorldDispatcher, body_id: u32) {
            let cosmic_body_type = get!(world, body_id, (CosmicBody));
            assert(cosmic_body_type.body_type == CosmicBodyType::Quasar, 'must be quasar');

            let emission_rate = get!(world, DUST_EMISSION_CONFIG_ID, DustEmissionConfig)
                .base_dust_emission;

            let current_ts = get_block_timestamp();

            set!(
                world,
                (
                    DustEmission {
                        entity: body_id, emission_rate, ARPS: 0, last_update_ts: current_ts
                    },
                )
            );
        }

        fn enter_dust_pool(world: IWorldDispatcher, body_id: u32, pool_id: u32) {
            let child_orbit = get!(world, body_id, (Orbit));
            assert(child_orbit.orbit_center == pool_id, 'not in orbit');

            let child_dust_accretion = get!(world, body_id, (DustAccretion));
            assert(child_dust_accretion.in_dust_pool == false, 'already in dust pool');

            let child_mass = get!(world, body_id, (Mass));
            let parent_mass = get!(world, pool_id, (Mass));
            let parent_emission = get!(world, pool_id, (DustEmission));

            let min_allowed_mass = child_mass.mass * 10;
            assert(parent_mass.mass >= min_allowed_mass, 'pool mass too low');

            Self::update_emission(world, pool_id);
            Self::increase_total_pool_mass(world, pool_id, child_mass.mass);

            set!(
                world,
                (DustAccretion {
                    entity: body_id,
                    debt: parent_emission.ARPS * child_mass.mass.try_into().unwrap(),
                    in_dust_pool: true
                })
            );
        }

        fn exit_dust_pool(world: IWorldDispatcher, body_id: u32) {
            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;

            let body_dust_accretion = get!(world, body_id, DustAccretion);
            assert(body_dust_accretion.in_dust_pool, 'not in dust pool');

            let body_mass = get!(world, body_id, Mass);

            Self::update_emission(world, body_id);
            Self::claim_dust(world, body_id);
            Self::decrease_total_pool_mass(world, pool_id, body_mass.mass);

            delete!(world, (body_dust_accretion));
        }

        fn update_emission(world: IWorldDispatcher, pool_id: u32) {
            let dust_emission = get!(world, pool_id, (DustEmission));
            assert(dust_emission.emission_rate > 0, 'no emission');

            let pool_mass = get!(world, pool_id, (DustPool));
            if pool_mass.total_mass == 0 {
                return;
            };

            let current_ts = get_block_timestamp();

            let updated_ARPS = calculate_ARPS(current_ts, dust_emission, pool_mass.total_mass);

            set!(
                world,
                (DustEmission {
                    entity: pool_id,
                    emission_rate: dust_emission.emission_rate,
                    ARPS: updated_ARPS,
                    last_update_ts: current_ts,
                })
            );
        }

        fn update_local_pool(world: IWorldDispatcher, body_id: u32) {
            let body_accretion = get!(world, body_id, (DustAccretion));
            assert(body_accretion.in_dust_pool, 'not in dust pool');

            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;
            Self::update_emission(world, pool_id);

            let pool_emission = get!(world, pool_id, (DustEmission));
            let body_mass = get!(world, body_id, (Mass));
            let unclaimed_pool_dust = calculate_unclaimed_dust(
                pool_emission, body_accretion, body_mass
            );

            let body_attributes = get!(world, body_id, BasalAttributes);
            let body_sense = body_attributes.get_attribute_value(BasalAttributesType::Sense);
            let body_unclaimed_dust = unclaimed_pool_dust * body_sense.try_into().unwrap() / 100;

            let current_dust = get!(world, body_id, (DustBalance));
            let new_dust_balance = current_dust.balance + body_unclaimed_dust;
            let dust_remainder = unclaimed_pool_dust - body_unclaimed_dust;
            let body_position = get!(world, body_id, Position);
            let dust_cloud = get!(
                world, (body_position.vec.x, body_position.vec.y, pool_id), DustCloud
            );
            set!(
                world,
                (
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
                        dust_balance: dust_cloud.dust_balance + dust_remainder
                    }
                )
            );
        }

        fn update_pool_member(world: IWorldDispatcher, body_id: u32, old_mass: u64, new_mass: u64) {
            assert(old_mass != new_mass, 'no mass change');

            let body_accretion = get!(world, body_id, DustAccretion);
            assert(body_accretion.in_dust_pool, 'not in dust pool');

            let body_orbit = get!(world, body_id, Orbit);
            let pool_id = body_orbit.orbit_center;
            let pool_emission = get!(world, pool_id, DustEmission);
            assert(pool_emission.emission_rate > 0, 'invalid pool id');

            Self::update_emission(world, pool_id);
            Self::claim_dust(world, body_id);

            if old_mass > new_mass {
                Self::decrease_total_pool_mass(world, pool_id, old_mass - new_mass);
            } else {
                Self::increase_total_pool_mass(world, pool_id, new_mass - old_mass);
            }
        }

        fn increase_total_pool_mass(world: IWorldDispatcher, pool_id: u32, mass: u64) {
            let pool_mass_data = get!(world, pool_id, DustPool);
            set!(
                world, (DustPool { entity: pool_id, total_mass: pool_mass_data.total_mass + mass })
            );
        }

        fn decrease_total_pool_mass(world: IWorldDispatcher, pool_id: u32, mass: u64) {
            let pool_mass_data = get!(world, pool_id, DustPool);
            set!(
                world, (DustPool { entity: pool_id, total_mass: pool_mass_data.total_mass - mass })
            );
        }

        fn claim_dust(world: IWorldDispatcher, body_id: u32) {
            let body_accretion = get!(world, body_id, (DustAccretion));
            assert(body_accretion.in_dust_pool, 'not in dust pool');

            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;
            let pool_emission = get!(world, pool_id, (DustEmission));
            let body_mass = get!(world, body_id, (Mass));
            let unclaimed_dust = calculate_unclaimed_dust(pool_emission, body_accretion, body_mass);

            let current_dust = get!(world, body_id, (DustBalance));
            let new_dust_balance = current_dust.balance + unclaimed_dust;

            set!(
                world,
                (
                    DustBalance { entity: body_id, balance: new_dust_balance },
                    DustAccretion { entity: body_id, debt: new_dust_balance, in_dust_pool: true }
                )
            );
        }

        fn consume_dust(world: IWorldDispatcher, body_id: u32, amount: u128) {
            let dust_balance = get!(world, body_id, (DustBalance));
            assert(dust_balance.balance >= amount, 'insufficient dust');

            let new_dust_balance = dust_balance.balance - amount;

            set!(world, (DustBalance { entity: body_id, balance: new_dust_balance }));
        }

        fn begin_dust_harvest(world: IWorldDispatcher, body_id: u32, harvest_amount: u128) {
            let caller = get_caller_address();
            let owner = get!(world, body_id, Owner);
            assert(caller == owner.address, 'not owner');

            let body_type = get!(world, body_id, CosmicBody);
            assert(body_type.body_type == CosmicBodyType::AsteroidCluster, 'invalid body type');

            let body_position = get!(world, body_id, Position);
            let body_orbit = get!(world, body_id, Orbit);
            let dust_cloud = get!(
                world,
                (body_position.vec.x, body_position.vec.y, body_orbit.orbit_center),
                DustCloud
            );
            assert(dust_cloud.dust_balance >= harvest_amount, 'not enough dust');

            let body_mass = get!(world, body_id, Mass);
            assert(body_mass.mass.try_into().unwrap() >= harvest_amount, 'harvest amount too high');

            // CHECK FOR ACTIONS
            let harvest_action = get!(world, body_id, HarvestAction);
            assert(harvest_action.end_ts == 0, 'entity already harvesting');
            let travel_action = get!(world, body_id, TravelAction);
            assert(travel_action.arrival_ts == 0, 'cannot harvest while travelling');

            let cur_ts = get_block_timestamp();
            let end_ts = get_harvest_end_ts(world, cur_ts, harvest_amount, body_mass.mass);

            set!(
                world, (HarvestAction { entity: body_id, start_ts: cur_ts, end_ts, harvest_amount })
            );
        }

        fn end_dust_harvest(world: IWorldDispatcher, body_id: u32) {
            let caller = get_caller_address();
            let owner = get!(world, body_id, Owner);
            assert(caller == owner.address, 'not owner');

            let body_position = get!(world, body_id, Position);
            let body_orbit = get!(world, body_id, Orbit);
            let dust_cloud = get!(
                world,
                (body_position.vec.x, body_position.vec.y, body_orbit.orbit_center),
                DustCloud
            );

            let cur_ts = get_block_timestamp();
            let harvest_action = get!(world, body_id, HarvestAction);
            assert(harvest_action.end_ts != 0, 'not harvesting');
            assert(cur_ts >= harvest_action.end_ts, 'harvest still underway');

            delete!(world, (harvest_action));

            let body_dust_balance = get!(world, body_id, DustBalance);
            let harvested_dust = if harvest_action.harvest_amount > dust_cloud.dust_balance {
                dust_cloud.dust_balance
            } else {
                harvest_action.harvest_amount
            };

            set!(
                world,
                (
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
        }

        fn cancel_dust_harvest(world: IWorldDispatcher, body_id: u32) {
            let caller = get_caller_address();
            let owner = get!(world, body_id, Owner);
            assert(caller == owner.address, 'not owner');

            let harvest_action = get!(world, body_id, HarvestAction);
            assert(harvest_action.end_ts != 0, 'not harvesting');

            delete!(world, (harvest_action));
        }
    }
}

