// Define the interface for the Dust system
#[dojo::interface]
trait IDustSystem {
    fn form_dust_pool(ref world: IWorldDispatcher, body_id: u32);
    fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32);
    fn exit_dust_pool(ref world: IWorldDispatcher, body_id: u32);
    fn claim_dust(ref world: IWorldDispatcher, body_id: u32);
    fn update_dust_pool(ref world: IWorldDispatcher, body_id: u32);
    fn get_dust_balance(ref world: IWorldDispatcher, body_id: u32) -> u128;
    fn consume_dust(ref world: IWorldDispatcher, body_id: u32, amount: u128);
}

// Dojo decorator
#[dojo::contract]
mod dust_system {
    use super::IDustSystem;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::models::{
        dust_balance::DustBalance, dust_accretion::DustAccretion, dust_emission::DustEmission,
        orbit::Orbit, mass::Mass
    };

    // Structure to represent a DustPoolFormed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct DustPoolFormed {
        #[key]
        body_id: u32,
        timestamp: u64,
    }

    // Structure to represent a DustPoolEntered event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct DustPoolEntered {
        #[key]
        body_id: u32,
        pool_id: u32,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct DustPoolExited {
        #[key]
        body_id: u32,
        pool_id: u32,
    }

    // Structure to represent DustClaimed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct DustClaimed {
        #[key]
        body_id: u32,
        amount: u128,
    }

    // Structure to represent DustConsumed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct DustConsumed {
        #[key]
        body_id: u32,
        amount: u128,
    }

    #[abi(embed_v0)]
    impl DustSystemImpl of IDustSystem<ContractState> {
        fn form_dust_pool(ref world: IWorldDispatcher, body_id: u32) {
            let emission_rate = 1000;
            let current_ts = get_block_timestamp();

            set!(
                world,
                (DustEmission {
                    entity: body_id, emission_rate, ARPS: 0, last_update_ts: current_ts
                })
            );

            emit!(world, (DustPoolFormed { body_id, timestamp: current_ts }));
        }

        fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32) {
            InternalDustSystemImpl::update_pool(world, pool_id);

            let child_mass = get!(world, body_id, (Mass));
            let parent_mass = get!(world, pool_id, (Mass));
            let parent_emission = get!(world, pool_id, (DustEmission));

            let min_allowed_mass = child_mass.mass * 10;
            assert(parent_mass.mass >= min_allowed_mass, 'pool mass too low');

            set!(
                world,
                (DustAccretion {
                    entity: body_id,
                    debt: parent_emission.ARPS * child_mass.mass.try_into().unwrap()
                })
            );

            emit!(world, (DustPoolEntered { body_id, pool_id }));
        }

        fn exit_dust_pool(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemImpl::claim_dust(world, body_id);

            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;

            let child_mass = get!(world, body_id, (Mass));
            let parent_mass = get!(world, pool_id, (Mass));

            set!(
                world,
                (Mass {
                    entity: pool_id,
                    mass: parent_mass.mass,
                    orbit_mass: parent_mass.orbit_mass - child_mass.mass
                })
            );

            emit!(world, (DustPoolExited { body_id, pool_id }));
        }

        fn claim_dust(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemImpl::claim_dust(world, body_id);
        }

        fn update_dust_pool(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemImpl::update_pool(world, body_id);
        }

        fn get_dust_balance(ref world: IWorldDispatcher, body_id: u32) -> u128 {
            let dust_balance = get!(world, body_id, (DustBalance));

            return dust_balance.balance;
        }

        fn consume_dust(ref world: IWorldDispatcher, body_id: u32, amount: u128) {
            let dust_balance = get!(world, body_id, (DustBalance));
            assert(dust_balance.balance >= amount, 'not enough dust');

            let new_dust_balance = dust_balance.balance - amount;

            set!(world, (DustBalance { entity: body_id, balance: new_dust_balance }));

            emit!(world, (DustConsumed { body_id, amount }));
        }
    }

    #[generate_trait]
    impl InternalDustSystemImpl of InternalDustSystemTrait {
        fn get_updated_ARPS(world: IWorldDispatcher, body_id: u32) -> u128 {
            let pool_mass = get!(world, body_id, (Mass));
            let pool_emission = get!(world, body_id, (DustEmission));

            let current_ts = get_block_timestamp();
            let reward_per_share = pool_emission.emission_rate
                / pool_mass.orbit_mass.try_into().unwrap();
            let elapsed_ts = current_ts - pool_emission.last_update_ts;
            let ARPS_change = reward_per_share * elapsed_ts.try_into().unwrap();

            let updated_ARPS = pool_emission.ARPS + ARPS_change;

            return updated_ARPS;
        }

        fn update_pool(world: IWorldDispatcher, body_id: u32) {
            let current_ts = get_block_timestamp();

            let updated_ARPS = Self::get_updated_ARPS(world, body_id);
            let dust_emission = get!(world, body_id, (DustEmission));

            set!(
                world,
                (DustEmission {
                    entity: body_id,
                    emission_rate: dust_emission.emission_rate,
                    ARPS: updated_ARPS,
                    last_update_ts: current_ts
                })
            );
        }

        fn get_unclaimed_dust(world: IWorldDispatcher, body_id: u32) -> u128 {
            let body_orbit = get!(world, body_id, (Orbit));
            let updated_ARPS = Self::get_updated_ARPS(world, body_orbit.orbit_center);

            // unclaimed dust
            let body_mass = get!(world, body_id, (Mass));
            let current_body_accretion = get!(world, body_id, (DustAccretion));
            let updated_body_accretion = updated_ARPS * body_mass.mass.try_into().unwrap();
            let unclaimed_dust = updated_body_accretion - current_body_accretion.debt;

            return unclaimed_dust;
        }

        fn claim_dust(world: IWorldDispatcher, body_id: u32) {
            // Check if claim dust was called without update_pool
            // If so, we need to update because get_unclaimed_dust is always current
            let orbit = get!(world, body_id, (Orbit));
            let pool_id = orbit.orbit_center;
            let pool_emission = get!(world, pool_id, (DustEmission));
            let current_ts = get_block_timestamp();
            if current_ts > pool_emission.last_update_ts {
                Self::update_pool(world, pool_id);
            }

            let current_dust = get!(world, body_id, (DustBalance));
            let unclaimed_dust = Self::get_unclaimed_dust(world, body_id);
            let new_dust_balance = current_dust.balance + unclaimed_dust;

            set!(world, (DustBalance { entity: body_id, balance: new_dust_balance }));

            emit!(world, (DustClaimed { body_id, amount: unclaimed_dust }));
        }
    }
}
