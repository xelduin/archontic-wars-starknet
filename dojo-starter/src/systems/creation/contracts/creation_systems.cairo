use starknet::{ContractAddress, get_caller_address};
use dojo_starter::models::vec2::Vec2;

// Define the interface for the Body creation system
#[dojo::interface]
trait ICreationSystems {
    fn create_galaxy(ref world: IWorldDispatcher);
    fn create_protostar(ref world: IWorldDispatcher, coords: Vec2, galaxy_id: u32);
    fn form_star(ref world: IWorldDispatcher, protostar_id: u32);
    fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32, amount: u64);
    fn create_asteroid_cluster(ref world: IWorldDispatcher, star_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod creation_systems {
    use super::ICreationSystems;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::models::{
        owner::Owner, position::Position, mass::Mass, incubation::Incubation, loosh_sink::LooshSink,
        vec2::Vec2
    };
    use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use dojo_starter::systems::{
        dust::contracts::dust_systems::dust_systems::{InternalDustSystemsImpl},
        loosh::contracts::loosh_systems::loosh_systems::{InternalLooshSystemsImpl, get_loosh_cost},
        authority::contracts::authority_systems::authority_systems::{InternalAuthoritySystemsImpl},
        mass::contracts::mass_systems::mass_systems::{InternalMassSystemsImpl},
        movement::contracts::movement_systems::movement_systems::{InternalMovementSystemsImpl}
    };

    // Structure to represent a ProtostarSpawned event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct ProtostarSpawned {
        #[key]
        body_id: u32,
        x: u64,
        y: u64,
    }

    // Structure to represent a StarFormed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct StarFormed {
        #[key]
        protostar_id: u32,
        timestamp: u64,
    }

    // Structure to represent AsteroidsFormed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct AsteroidsFormed {
        #[key]
        star_id: u32,
        cluster_id: u32,
    }

    // Structure to represent AsteroidClusterDefined event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct AsteroidClusterDefined {
        #[key]
        star_id: u32,
        cluster_id: u32,
    }

    #[abi(embed_v0)]
    impl CreationSystemsImpl of ICreationSystems<ContractState> {
        fn create_galaxy(ref world: IWorldDispatcher) {
            InternalCreationSystemsImpl::create_galaxy(world);
        }

        fn create_protostar(ref world: IWorldDispatcher, coords: Vec2, galaxy_id: u32) {
            InternalCreationSystemsImpl::create_protostar(world, coords, galaxy_id);
        }

        fn form_star(ref world: IWorldDispatcher, protostar_id: u32) {
            InternalCreationSystemsImpl::form_star(world, protostar_id);
        }

        fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32, amount: u64) {
            InternalCreationSystemsImpl::form_asteroids(world, star_id, cluster_id, amount);
        }

        fn create_asteroid_cluster(ref world: IWorldDispatcher, star_id: u32) {
            InternalCreationSystemsImpl::create_asteroid_cluster(world, star_id);
        }
    }

    #[generate_trait]
    impl InternalCreationSystemsImpl of InternalCreationSystemsTrait {
        fn create_galaxy(world: IWorldDispatcher) {
            let player = get_caller_address();

            InternalLooshSystemsImpl::spend_loosh(world, player, LooshSink::CreateGalaxy);

            let body_id = world.uuid();
            set!(world, (CosmicBody { entity: body_id, body_type: CosmicBodyType::Galaxy },));

            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, player);

            let mass = 10000;
            InternalMassSystemsImpl::increase_mass(world, body_id, mass);

            InternalDustSystemsImpl::form_dust_pool(world, body_id);
        }

        fn create_protostar(world: IWorldDispatcher, coords: Vec2, galaxy_id: u32) {
            // Retrieve the current caller's address
            let player = get_caller_address();

            InternalLooshSystemsImpl::spend_loosh(world, player, LooshSink::CreateProtostar);

            let body_id = world.uuid();
            let creation_ts = get_block_timestamp();
            let incubation_period = 60 * 1000;

            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type: CosmicBodyType::Protostar },
                    Incubation {
                        entity: body_id, creation_ts, end_ts: creation_ts + incubation_period
                    },
                    Position { entity: body_id, vec: coords }
                )
            );
            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, player);

            let mass = 1000;
            InternalMassSystemsImpl::increase_mass(world, body_id, mass);

            InternalMovementSystemsImpl::enter_orbit(world, body_id, galaxy_id);
            InternalDustSystemsImpl::enter_dust_pool(world, body_id, galaxy_id);

            emit!(world, (ProtostarSpawned { body_id, x: coords.x, y: coords.y }));
        }

        fn create_asteroid_cluster(world: IWorldDispatcher, star_id: u32) {
            let star_body = get!(world, star_id, (CosmicBody));
            assert(star_body.body_type == CosmicBodyType::Star, 'not a star');

            let player = get_caller_address();
            InternalLooshSystemsImpl::spend_loosh(world, player, LooshSink::CreateAsteroidCluster);

            let body_id = world.uuid();
            let star_position = get!(world, star_id, (Position));
            let player = get_caller_address();
            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type: CosmicBodyType::AsteroidCluster },
                    Position { entity: body_id, vec: star_position.vec },
                )
            );
            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, player);

            InternalMovementSystemsImpl::enter_orbit(world, body_id, star_id);
            InternalDustSystemsImpl::enter_dust_pool(world, body_id, star_id);

            emit!(world, (AsteroidClusterDefined { star_id, cluster_id: body_id }));
        }

        fn form_star(world: IWorldDispatcher, protostar_id: u32) {
            let player = get_caller_address();

            let protostar_incubation = get!(world, protostar_id, (Incubation));
            let current_ts = get_block_timestamp();
            assert(current_ts >= protostar_incubation.end_ts, 'incubation period not over');

            InternalLooshSystemsImpl::spend_loosh(world, player, LooshSink::FormStar);

            set!(world, (CosmicBody { entity: protostar_id, body_type: CosmicBodyType::Star }));
        }

        fn form_asteroids(world: IWorldDispatcher, star_id: u32, cluster_id: u32, mass: u64) {
            let star_body = get!(world, star_id, (CosmicBody));
            assert(star_body.body_type == CosmicBodyType::Star, 'not a star');

            InternalDustSystemsImpl::consume_dust(world, star_id, mass.try_into().unwrap());
            InternalMassSystemsImpl::increase_mass(world, cluster_id, mass);
            // Emit an event for asteroid formation
            emit!(world, (AsteroidsFormed { star_id, cluster_id }));
        }
    }
}
