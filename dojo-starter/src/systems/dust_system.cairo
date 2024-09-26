use dojo_starter::models::{
    dust_emission::DustEmission, dust_accretion::DustAccretion, orbit::Orbit, mass::Mass
};


// Define the interface for the Dust system
#[dojo::interface]
trait IDustSystem {
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
    use super::{IDustSystem, calculate_ARPS, calculate_unclaimed_dust};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::models::{
        dust_balance::DustBalance, dust_accretion::DustAccretion, dust_emission::DustEmission,
        orbit::Orbit, mass::Mass, cosmic_body::{CosmicBody, CosmicBodyType}
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
        fn enter_dust_pool(ref world: IWorldDispatcher, body_id: u32, pool_id: u32) {
            InternalDustSystemImpl::enter_dust_pool(world, body_id, pool_id);
        }

        fn exit_dust_pool(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemImpl::exit_dust_pool(world, body_id);
        }

        fn claim_dust(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemImpl::claim_dust(world, body_id);
        }

        fn update_dust_pool(ref world: IWorldDispatcher, body_id: u32) {
            InternalDustSystemImpl::update_emission(world, body_id);
        }

        fn get_dust_balance(ref world: IWorldDispatcher, body_id: u32) -> u128 {
            let dust_balance = get!(world, body_id, (DustBalance));

            return dust_balance.balance;
        }

        fn consume_dust(ref world: IWorldDispatcher, body_id: u32, amount: u128) {
            InternalDustSystemImpl::consume_dust(world, body_id, amount);
        }
    }

    #[generate_trait]
    impl InternalDustSystemImpl of InternalDustSystemTrait {
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
            Self::claim_dust(world, body_id);

            let body_orbit = get!(world, body_id, (Orbit));
            let pool_id = body_orbit.orbit_center;

            emit!(world, (DustPoolExited { body_id, pool_id }));
        }

        fn update_emission(world: IWorldDispatcher, body_id: u32) {
            let current_ts = get_block_timestamp();

            let dust_emission = get!(world, body_id, (DustEmission));
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
            let orbit = get!(world, body_id, (Orbit));
            let pool_id = orbit.orbit_center;
            Self::update_emission(world, pool_id);

            let pool_emission = get!(world, pool_id, (DustEmission));
            let body_accretion = get!(world, body_id, (DustAccretion));
            let body_mass = get!(world, body_id, (Mass));
            let unclaimed_dust = calculate_unclaimed_dust(pool_emission, body_accretion, body_mass);

            let current_dust = get!(world, body_id, (DustBalance));
            let new_dust_balance = current_dust.balance + unclaimed_dust;

            set!(world, (DustBalance { entity: body_id, balance: new_dust_balance }));

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

fn calculate_unclaimed_dust(
    dust_emission: DustEmission, dust_accretion: DustAccretion, body_mass: Mass
) -> u128 {
    let updated_body_accretion = dust_emission.ARPS * body_mass.mass.try_into().unwrap();
    let unclaimed_dust = updated_body_accretion - dust_accretion.debt;

    return unclaimed_dust;
}


fn calculate_ARPS(current_ts: u64, pool_emission: DustEmission, pool_mass: Mass) -> u128 {
    let reward_per_share = pool_emission.emission_rate / pool_mass.orbit_mass.try_into().unwrap();
    let elapsed_ts = current_ts - pool_emission.last_update_ts;
    let ARPS_change = reward_per_share * elapsed_ts.try_into().unwrap();

    let updated_ARPS = pool_emission.ARPS + ARPS_change;

    return updated_ARPS;
}
