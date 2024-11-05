use starknet::{ContractAddress, get_caller_address};
use astraplani::models::vec2::Vec2;

// Define the interface for the Body creation system
#[dojo::interface]
trait ICreationSystems {
    fn create_quasar(ref world: IWorldDispatcher, coords: Vec2) -> u32;
    fn create_protostar(ref world: IWorldDispatcher, coords: Vec2, quasar_id: u32) -> u32;
    fn create_asteroid_cluster(ref world: IWorldDispatcher, coords: Vec2, star_id: u32) -> u32;
    fn form_star(ref world: IWorldDispatcher, protostar_id: u32);
    fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32, amount: u64);
}

// Dojo decorator
#[dojo::contract]
mod creation_systems {
    use super::{ICreationSystems, get_loosh_cost};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};

    use astraplani::systems::dust::contracts::dust_systems::dust_systems::InternalDustSystemsImpl;
    use astraplani::systems::loosh::contracts::loosh_systems::loosh_systems::InternalLooshSystemsImpl;
    use astraplani::systems::mass::contracts::mass_systems::mass_systems::InternalMassSystemsImpl;
    use astraplani::systems::config::contracts::config_systems::config_systems::assert_caller_is_admin;

    use astraplani::constants::DUST_VALUE_CONFIG_ID;
    use astraplani::constants::ADMIN_CONFIG_ID;
    use astraplani::constants::COSMIC_BODY_MASS_CONFIG_ID;
    use astraplani::constants::INCUBATION_TIME_CONFIG_ID;

    use astraplani::models::config::DustValueConfig;
    use astraplani::models::config::AdminConfig;
    use astraplani::models::config::BaseCosmicBodyMassConfig;
    use astraplani::models::config::IncubationTimeConfig;

    use astraplani::models::owner::Owner;
    use astraplani::models::vec2::Vec2;
    use astraplani::models::position::{Position, OrbitCenterAtPosition};
    use astraplani::models::orbit::Orbit;
    use astraplani::models::orbital_mass::OrbitalMass;
    use astraplani::models::mass::Mass;
    use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use astraplani::models::incubation::Incubation;
    use astraplani::models::loosh_sink::LooshSink;
    use astraplani::models::basal_attributes::BasalAttributes;

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct QuasarCreated {
        #[key]
        body_id: u32,
        owner: ContractAddress,
        mass: u64,
        coords: Vec2,
        parent_id: u32,
        creation_ts: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct ProtostarCreated {
        #[key]
        body_id: u32,
        owner: ContractAddress,
        mass: u64,
        coords: Vec2,
        parent_id: u32,
        creation_ts: u64,
        incubation_end_ts: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct AsteroidClusterCreated {
        #[key]
        body_id: u32,
        owner: ContractAddress,
        mass: u64,
        coords: Vec2,
        parent_id: u32,
        creation_ts: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct StarFormed {
        #[key]
        body_id: u32,
        creation_ts: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct AsteroidsFormed {
        #[key]
        body_id: u32,
        mass: u64,
        creation_ts: u64,
    }

    #[abi(embed_v0)]
    impl CreationSystemsImpl of ICreationSystems<ContractState> {
        fn create_quasar(ref world: IWorldDispatcher, coords: Vec2) -> u32 {
            return InternalCreationSystemsImpl::create_quasar(world, coords);
        }

        fn create_protostar(ref world: IWorldDispatcher, coords: Vec2, quasar_id: u32) -> u32 {
            return InternalCreationSystemsImpl::create_protostar(world, coords, quasar_id);
        }

        fn create_asteroid_cluster(ref world: IWorldDispatcher, coords: Vec2, star_id: u32) -> u32 {
            return InternalCreationSystemsImpl::create_asteroid_cluster(
                world, coords, star_id, initial_mass: 100
            );
        }

        fn form_star(ref world: IWorldDispatcher, protostar_id: u32) {
            InternalCreationSystemsImpl::form_star(world, protostar_id);
        }

        fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32, amount: u64) {
            InternalCreationSystemsImpl::form_asteroids(world, star_id, cluster_id, amount);
        }
    }

    #[generate_trait]
    impl InternalCreationSystemsImpl of InternalCreationSystemsTrait {
        fn create_quasar(world: IWorldDispatcher, coords: Vec2) -> u32 {
            assert_caller_is_admin(world);

            let central_entity_at_pos = get!(world, (coords.x, coords.y, 0), OrbitCenterAtPosition);
            assert(central_entity_at_pos.entity == 0, 'coords are occupied');

            let player = get_caller_address();
            let loosh_cost = get_loosh_cost(LooshSink::CreateQuasar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.uuid();
            let universe_id = 0;
            let mass = get!(world, COSMIC_BODY_MASS_CONFIG_ID, BaseCosmicBodyMassConfig)
                .base_quasar_mass;
            Self::create_cosmic_body(
                world, player, body_id, CosmicBodyType::Quasar, mass, universe_id, coords,
            );

            set!(
                world,
                (OrbitCenterAtPosition {
                    x: coords.x, y: coords.y, orbit_center: universe_id, entity: body_id
                })
            );
            emit!(
                world,
                QuasarCreated {
                    body_id,
                    owner: player,
                    mass,
                    coords,
                    parent_id: universe_id,
                    creation_ts: get_block_timestamp()
                }
            );

            InternalDustSystemsImpl::form_dust_pool(world, body_id);

            return body_id;
        }

        fn create_protostar(world: IWorldDispatcher, coords: Vec2, quasar_id: u32) -> u32 {
            let quasar_body = get!(world, quasar_id, CosmicBody);
            assert(quasar_body.body_type == CosmicBodyType::Quasar, 'invalid quasar id');

            let central_entity_at_pos = get!(
                world, (coords.x, coords.y, quasar_id), OrbitCenterAtPosition
            );
            assert(central_entity_at_pos.entity == 0, 'coords are occupied');

            let player = get_caller_address();
            let loosh_cost = get_loosh_cost(LooshSink::CreateProtostar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.uuid();
            let mass = get!(world, COSMIC_BODY_MASS_CONFIG_ID, BaseCosmicBodyMassConfig)
                .base_star_mass;
            Self::create_cosmic_body(
                world, player, body_id, CosmicBodyType::Protostar, mass, quasar_id, coords,
            );

            let creation_ts = get_block_timestamp();
            let incubation_period = get!(world, INCUBATION_TIME_CONFIG_ID, IncubationTimeConfig)
                .base_incubation_time;
            let incubation_end_ts = creation_ts + incubation_period;
            let attributes = 20;
            set!(
                world,
                (
                    Incubation { entity: body_id, creation_ts, end_ts: incubation_end_ts },
                    OrbitCenterAtPosition {
                        x: coords.x, y: coords.y, orbit_center: quasar_id, entity: body_id
                    },
                    BasalAttributes { entity: body_id, attributes }
                )
            );
            emit!(
                world,
                (ProtostarCreated {
                    body_id,
                    owner: player,
                    mass,
                    coords,
                    parent_id: quasar_id,
                    creation_ts,
                    incubation_end_ts
                })
            );

            InternalDustSystemsImpl::enter_dust_pool(world, body_id, quasar_id);

            return body_id;
        }

        fn create_asteroid_cluster(
            world: IWorldDispatcher, coords: Vec2, star_id: u32, initial_mass: u64
        ) -> u32 {
            let star_body = get!(world, star_id, (CosmicBody));
            assert(star_body.body_type == CosmicBodyType::Star, 'invalid star id');

            let player = get_caller_address();
            let star_owner = get!(world, star_id, Owner);
            assert(star_owner.address == player, 'caller must own star');

            let loosh_cost = get_loosh_cost(LooshSink::CreateAsteroidCluster);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.uuid();
            Self::create_cosmic_body(
                world,
                player,
                body_id,
                CosmicBodyType::AsteroidCluster,
                initial_mass,
                star_id,
                coords,
            );

            emit!(
                world,
                AsteroidClusterCreated {
                    body_id,
                    owner: player,
                    mass: initial_mass,
                    coords,
                    parent_id: star_id,
                    creation_ts: get_block_timestamp(),
                }
            );

            return body_id;
        }

        fn create_cosmic_body(
            world: IWorldDispatcher,
            owner: ContractAddress,
            body_id: u32,
            body_type: CosmicBodyType,
            mass: u64,
            orbit_center: u32,
            coords: Vec2,
        ) {
            let orbit_center_orbital_mass = get!(world, orbit_center, OrbitalMass);

            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type },
                    Position { entity: body_id, vec: coords },
                    Orbit { entity: body_id, orbit_center },
                    Mass { entity: body_id, mass },
                    OrbitalMass {
                        entity: orbit_center,
                        orbital_mass: orbit_center_orbital_mass.orbital_mass + mass
                    },
                    Owner { entity: body_id, address: owner }
                )
            );
        }

        fn form_star(world: IWorldDispatcher, protostar_id: u32) {
            let player = get_caller_address();
            let protostar_owner = get!(world, protostar_id, Owner);
            assert(protostar_owner.address == player, 'caller must be owner');

            let protostar_body = get!(world, protostar_id, CosmicBody);
            assert(protostar_body.body_type == CosmicBodyType::Protostar, 'invalid protostar id');

            let protostar_incubation = get!(world, protostar_id, (Incubation));
            let current_ts = get_block_timestamp();
            assert(current_ts >= protostar_incubation.end_ts, 'incubation not over');

            let loosh_cost = get_loosh_cost(LooshSink::FormStar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            set!(world, (CosmicBody { entity: protostar_id, body_type: CosmicBodyType::Star }));
            delete!(world, (protostar_incubation));

            emit!(world, (StarFormed { body_id: protostar_id, creation_ts: current_ts }));
        }

        fn form_asteroids(world: IWorldDispatcher, star_id: u32, cluster_id: u32, mass: u64) {
            let player = get_caller_address();
            let star_owner = get!(world, star_id, Owner);
            assert(star_owner.address == player, 'caller must own star');

            let star_body = get!(world, star_id, CosmicBody);
            assert(star_body.body_type == CosmicBodyType::Star, 'invalid star id');

            let asteroid_cluster_body = get!(world, cluster_id, CosmicBody);
            assert(
                asteroid_cluster_body.body_type == CosmicBodyType::AsteroidCluster,
                'invalid asteroid cluster id'
            );

            let asteroid_cluster_orbit = get!(world, cluster_id, Orbit);
            assert(asteroid_cluster_orbit.orbit_center == star_id, 'asteroid cluster not in orbit');

            let dust_to_mass = get!(world, DUST_VALUE_CONFIG_ID, DustValueConfig).dust_to_mass;
            let dust_to_consume = dust_to_mass * mass.try_into().unwrap();

            InternalDustSystemsImpl::consume_dust(world, star_id, dust_to_consume);
            InternalMassSystemsImpl::increase_mass(world, cluster_id, mass);

            emit!(
                world,
                (AsteroidsFormed { body_id: cluster_id, mass, creation_ts: get_block_timestamp() })
            );
        }
    }
}

use astraplani::models::loosh_sink::LooshSink;

fn get_loosh_cost(sink: LooshSink) -> u128 {
    match sink {
        LooshSink::CreateQuasar => 1000,
        LooshSink::CreateProtostar => 100,
        LooshSink::FormStar => 20,
        LooshSink::CreateAsteroidCluster => 10,
    }
}
