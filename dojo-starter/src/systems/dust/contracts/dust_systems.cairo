use dojo_starter::models::{
    dust_emission::DustEmission, dust_accretion::DustAccretion, orbit::Orbit, mass::Mass
};


// Define the interface for the Dust system
#[dojo::interface]
trait IDustSystems {
    fn claim_dust(ref world: IWorldDispatcher, body_id: u32);
    fn update_emission(ref world: IWorldDispatcher, body_id: u32);
    fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod dust_systems {
    use super::{IDustSystems};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::utils::dust_farm::{calculate_ARPS, calculate_unclaimed_dust};

    use dojo_starter::models::dust_pool::DustPool;
    use dojo_starter::models::dust_balance::DustBalance;
    use dojo_starter::models::dust_accretion::DustAccretion;
    use dojo_starter::models::dust_emission::DustEmission;
    use dojo_starter::models::orbit::Orbit;
    use dojo_starter::models::mass::Mass;
    use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};


    #[abi(embed_v0)]
    impl DustSystemsImpl of IDustSystems<ContractState> {
        fn claim_dust(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemsImpl::claim_dust(world, body_id);
        }

        fn update_emission(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemsImpl::update_emission(world, body_id);
        }

        fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32) {
            InternalDustSystemsImpl::enter_dust_pool(world, body_id, pool_id);
        }
    }

    #[generate_trait]
    impl InternalDustSystemsImpl of InternalDustSystemsTrait {
        fn form_dust_pool(world: IWorldDispatcher, body_id: u32) {
            let cosmic_body_type = get!(world, body_id, (CosmicBody));
            assert(cosmic_body_type.body_type == CosmicBodyType::Galaxy, 'must be galaxy');

            let emission_rate = 1000;
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
    }
}

