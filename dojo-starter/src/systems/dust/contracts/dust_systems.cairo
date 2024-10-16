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
    use dojo_starter::models::{
        dust_balance::DustBalance, dust_accretion::DustAccretion, dust_emission::DustEmission,
        orbit::Orbit, mass::Mass, cosmic_body::{CosmicBody, CosmicBodyType}
    };
    use dojo_starter::utils::dust_farm::{calculate_ARPS, calculate_unclaimed_dust};

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
                (DustEmission {
                    entity: body_id, emission_rate, ARPS: 0, last_update_ts: current_ts
                })
            );

            emit!(world, (DustPoolFormed { body_id, timestamp: current_ts }));
        }

        fn enter_dust_pool(world: IWorldDispatcher, body_id: u32, pool_id: u32) {
            let child_orbit = get!(world, body_id, (Orbit));
            assert(child_orbit.orbit_center == pool_id, 'not in orbit');

            Self::update_emission(world, pool_id);

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

        fn exit_dust_pool(world: IWorldDispatcher, body_id: u32) {
            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;
            //assert(body_orbit.orbit_center == pool_id, 'not in orbit');

            Self::update_emission(world, body_id);
            Self::claim_dust(world, body_id);

            emit!(world, (DustPoolExited { body_id, pool_id }));
        }

        fn update_emission(world: IWorldDispatcher, body_id: u32) {
            let current_ts = get_block_timestamp();

            let dust_emission = get!(world, body_id, (DustEmission));
            assert(dust_emission.emission_rate > 0, 'no emission');
            let body_mass = get!(world, body_id, (Mass));

            let updated_ARPS = calculate_ARPS(current_ts, dust_emission, body_mass);

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

        fn claim_dust(world: IWorldDispatcher, body_id: u32) {
            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;
            assert(pool_id != 0, 'not in a pool');

            let pool_emission = get!(world, pool_id, (DustEmission));
            let body_accretion = get!(world, body_id, (DustAccretion));
            let body_mass = get!(world, body_id, (Mass));
            let unclaimed_dust = calculate_unclaimed_dust(pool_emission, body_accretion, body_mass);

            let current_dust = get!(world, body_id, (DustBalance));
            let new_dust_balance = current_dust.balance + unclaimed_dust;

            set!(
                world,
                (
                    DustBalance { entity: body_id, balance: new_dust_balance },
                    DustAccretion { entity: body_id, debt: pool_emission.ARPS }
                )
            );

            emit!(world, (DustClaimed { body_id, amount: unclaimed_dust }));
        }

        fn consume_dust(world: IWorldDispatcher, body_id: u32, amount: u128) {
            let dust_balance = get!(world, body_id, (DustBalance));
            assert(dust_balance.balance >= amount, 'not enough dust');

            let new_dust_balance = dust_balance.balance - amount;

            set!(world, (DustBalance { entity: body_id, balance: new_dust_balance }));

            emit!(world, (DustConsumed { body_id, amount }));
        }
    }
}

