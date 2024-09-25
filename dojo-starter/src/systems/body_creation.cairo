use starknet::{ContractAddress, get_caller_address};

// Define the interface for the Body creation system
#[dojo::interface]
trait IBodyCreation {
    fn create_protostar(ref world: IWorldDispatcher, x: u64, y: u64);
    fn form_star(ref world: IWorldDispatcher, protostar_id: u32);
    fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32);
    fn create_asteroid_cluster(ref world: IWorldDispatcher, star_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod body_creation {
    use super::IBodyCreation;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::models::{
        owner::Owner, position::Position, mass::Mass, incubation::Incubation, loosh_sink::LooshSink,
        vec2::Vec2
    };
    use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use dojo_starter::systems::{
        dust_system::dust_system::{InternalDustSystemImpl},
        loosh_system::loosh_system::{InternalLooshSystemImpl, get_loosh_cost},
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
    impl BodyCreationImpl of IBodyCreation<ContractState> {
        fn create_protostar(ref world: IWorldDispatcher, x: u64, y: u64) {
            InternalBodyCreationImpl::create_protostar(world, x, y);
        }

        fn form_star(ref world: IWorldDispatcher, protostar_id: u32) {
            InternalBodyCreationImpl::form_star(world, protostar_id);
        }

        fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32) {
            InternalBodyCreationImpl::form_asteroids(world, star_id, cluster_id);
        }

        fn create_asteroid_cluster(ref world: IWorldDispatcher, star_id: u32) {
            InternalBodyCreationImpl::create_asteroid_cluster(world, star_id);
        }
    }

    #[generate_trait]
    impl InternalBodyCreationImpl of InternalBodyCreationTrait {
        fn create_protostar(world: IWorldDispatcher, x: u64, y: u64) {
            // Retrieve the current caller's address
            let player = get_caller_address();

            InternalLooshSystemImpl::spend_loosh(world, player, LooshSink::CreateProtostar);

            let body_id = world.uuid();
            let creation_ts = get_block_timestamp();
            let incubation_period = 60 * 1000;
            let mass = 1000;

            set!(
                world,
                (
                    Incubation {
                        entity: body_id, creation_ts, end_ts: creation_ts + incubation_period
                    },
                    Owner { entity: body_id, address: player },
                    Mass { entity: body_id, mass, orbit_mass: 0 },
                    Position { entity: body_id, vec: Vec2 { x, y } }
                )
            );

            let pool_id = 0; //TODO

            InternalDustSystemImpl::enter_dust_pool(world, body_id, pool_id);

            emit!(world, (ProtostarSpawned { body_id, x, y }));
        }

        fn create_asteroid_cluster(world: IWorldDispatcher, star_id: u32) {
            let star_body = get!(world, star_id, (CosmicBody));
            assert(star_body.body_type == CosmicBodyType::Star, 'not a star');

            let player = get_caller_address();
            InternalLooshSystemImpl::spend_loosh(world, player, LooshSink::CreateAsteroidCluster);

            let body_id = world.uuid();
            let star_position = get!(world, star_id, (Position));
            let player = get_caller_address();
            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type: CosmicBodyType::AsteroidCluster },
                    Position { entity: body_id, vec: star_position.vec },
                    Owner { entity: body_id, address: player },
                )
            );

            InternalDustSystemImpl::enter_dust_pool(world, body_id, star_id);

            emit!(world, (AsteroidClusterDefined { star_id, cluster_id: body_id }));
        }

        fn form_star(world: IWorldDispatcher, protostar_id: u32) {
            // 1. Check ownership: ensure the caller is the owner of the protostar.
            let player = get_caller_address();
            let protostar_owner = get!(world, protostar_id, (Owner));
            assert(player == protostar_owner.address, 'isnt owner');

            // 2. Check if the incubation period is over.
            let protostar_incubation = get!(world, protostar_id, (Incubation));
            let current_ts = get_block_timestamp();
            assert(current_ts >= protostar_incubation.end_ts, 'incubation period not over');

            InternalLooshSystemImpl::spend_loosh(world, player, LooshSink::FormStar);

            set!(world, (CosmicBody { entity: protostar_id, body_type: CosmicBodyType::Star }));
        }

        fn form_asteroids(world: IWorldDispatcher, star_id: u32, cluster_id: u32) {
            // 1. Verify that the body is a Star.
            let star_body = get!(world, star_id, (CosmicBody));
            assert(star_body.body_type == CosmicBodyType::Star, 'not a star');

            let asteroid_mass = 100;
            // 4. Call consume_dust for dust processing.
            //InternalDustSystemImpl::spend_dust(world, star_id, cluster_id)

            let cluster_mass = get!(world, cluster_id, (Mass));
            set!(
                world,
                (Mass {
                    entity: cluster_id, mass: cluster_mass.mass + asteroid_mass, orbit_mass: 0
                })
            );

            // Emit an event for asteroid formation
            emit!(world, (AsteroidsFormed { star_id, cluster_id }));
        }
    }
}
