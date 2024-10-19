use starknet::{ContractAddress, get_caller_address};
use dojo_starter::models::vec2::Vec2;

// Define the interface for the Body creation system
#[dojo::interface]
trait ICreationSystems {
    fn create_galaxy(ref world: IWorldDispatcher, coords: Vec2) -> u32;
    fn create_protostar(ref world: IWorldDispatcher, coords: Vec2, galaxy_id: u32) -> u32;
    fn create_asteroid_cluster(ref world: IWorldDispatcher, coords: Vec2, star_id: u32) -> u32;
    fn form_star(ref world: IWorldDispatcher, protostar_id: u32);
    fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32, amount: u64);
}

// Dojo decorator
#[dojo::contract]
mod creation_systems {
    use super::{ICreationSystems, get_loosh_cost};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::models::{incubation::Incubation, loosh_sink::LooshSink, vec2::Vec2,};
    use dojo_starter::models::position::{Position, OrbitCenterAtPosition};
    use dojo_starter::models::owner::Owner;
    use dojo_starter::models::mass::Mass;
    use dojo_starter::models::orbit::Orbit;
    use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use dojo_starter::systems::{
        dust::contracts::dust_systems::dust_systems::{InternalDustSystemsImpl},
        loosh::contracts::loosh_systems::loosh_systems::{InternalLooshSystemsImpl},
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
        fn create_galaxy(ref world: IWorldDispatcher, coords: Vec2) -> u32 {
            return InternalCreationSystemsImpl::create_galaxy(world, coords);
        }

        fn create_protostar(ref world: IWorldDispatcher, coords: Vec2, galaxy_id: u32) -> u32 {
            return InternalCreationSystemsImpl::create_protostar(world, coords, galaxy_id);
        }

        fn create_asteroid_cluster(ref world: IWorldDispatcher, coords: Vec2, star_id: u32) -> u32 {
            return InternalCreationSystemsImpl::create_asteroid_cluster(
                world, coords, star_id, initial_mass: 1
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
        fn create_galaxy(world: IWorldDispatcher, coords: Vec2) -> u32 {
            let central_entity_at_pos = get!(world, (coords.x, coords.y, 0), OrbitCenterAtPosition);
            assert(central_entity_at_pos.entity == 0, 'coords are occupied');

            let player = get_caller_address();
            let loosh_cost = get_loosh_cost(LooshSink::CreateGalaxy);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.uuid();
            let mass = 10000;
            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type: CosmicBodyType::Galaxy },
                    Position { entity: body_id, vec: coords },
                    Mass { entity: body_id, mass, orbit_mass: 0 },
                    Owner { entity: body_id, address: player },
                    OrbitCenterAtPosition {
                        x: coords.x, y: coords.y, orbit_center: 0, entity: body_id
                    }
                )
            );

            //InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, player);
            InternalDustSystemsImpl::form_dust_pool(world, body_id);

            return body_id;
        }

        fn create_protostar(world: IWorldDispatcher, coords: Vec2, galaxy_id: u32) -> u32 {
            let galaxy_body = get!(world, galaxy_id, CosmicBody);
            assert(galaxy_body.body_type == CosmicBodyType::Galaxy, 'invalid galaxy id');

            let central_entity_at_pos = get!(
                world, (coords.x, coords.y, galaxy_id), OrbitCenterAtPosition
            );
            assert(central_entity_at_pos.entity == 0, 'coords are occupied');

            let player = get_caller_address();
            let loosh_cost = get_loosh_cost(LooshSink::CreateProtostar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.uuid();
            let creation_ts = get_block_timestamp();
            let incubation_period = 60 * 1000;

            let mass = 1000;
            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type: CosmicBodyType::Protostar },
                    Incubation {
                        entity: body_id, creation_ts, end_ts: creation_ts + incubation_period
                    },
                    Position { entity: body_id, vec: coords },
                    Orbit { entity: body_id, orbit_center: galaxy_id },
                    Mass { entity: body_id, mass, orbit_mass: 0 },
                    OrbitCenterAtPosition {
                        x: coords.x, y: coords.y, orbit_center: galaxy_id, entity: body_id
                    }
                )
            );

            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, player);
            InternalDustSystemsImpl::enter_dust_pool(world, body_id, galaxy_id);
            emit!(world, (ProtostarSpawned { body_id, x: coords.x, y: coords.y }));

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
            let player = get_caller_address();
            set!(
                world,
                (
                    CosmicBody { entity: body_id, body_type: CosmicBodyType::AsteroidCluster },
                    Position { entity: body_id, vec: coords },
                    Orbit { entity: body_id, orbit_center: star_id },
                    Mass { entity: body_id, mass: initial_mass, orbit_mass: 0 }
                )
            );
            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, player);

            // Will add when multilayered farming implemented
            //InternalDustSystemsImpl::enter_dust_pool(world, body_id, star_id);

            emit!(world, (AsteroidClusterDefined { star_id, cluster_id: body_id }));

            return body_id;
        }

        fn form_star(world: IWorldDispatcher, protostar_id: u32) {
            let player = get_caller_address();

            let protostar_body = get!(world, protostar_id, CosmicBody);
            assert(protostar_body.body_type == CosmicBodyType::Protostar, 'invalid protostar id');

            let protostar_owner = get!(world, protostar_id, Owner);
            assert(protostar_owner.address == player, 'caller must be owner');

            let protostar_incubation = get!(world, protostar_id, (Incubation));
            let current_ts = get_block_timestamp();
            assert(current_ts >= protostar_incubation.end_ts, 'incubation not over');

            let loosh_cost = get_loosh_cost(LooshSink::FormStar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            set!(world, (CosmicBody { entity: protostar_id, body_type: CosmicBodyType::Star }));
            delete!(world, (protostar_incubation));
        }

        fn form_asteroids(world: IWorldDispatcher, star_id: u32, cluster_id: u32, mass: u64) {
            let star_body = get!(world, star_id, CosmicBody);
            assert(star_body.body_type == CosmicBodyType::Star, 'invalid star id');

            let asteroid_cluster_body = get!(world, cluster_id, CosmicBody);
            assert(
                asteroid_cluster_body.body_type == CosmicBodyType::AsteroidCluster,
                'invalid asteroid cluster id'
            );

            let asteroid_cluster_orbit = get!(world, cluster_id, Orbit);
            assert(asteroid_cluster_orbit.orbit_center == star_id, 'asteroid cluster not in orbit');

            let player = get_caller_address();

            let star_owner = get!(world, star_id, Owner);
            assert(star_owner.address == player, 'caller must own star');

            InternalDustSystemsImpl::consume_dust(world, star_id, mass.try_into().unwrap());
            InternalMassSystemsImpl::increase_mass(world, cluster_id, mass);
            // Emit an event for asteroid formation
            emit!(world, (AsteroidsFormed { star_id, cluster_id }));
        }
    }
}

use dojo_starter::models::loosh_sink::LooshSink;

fn get_loosh_cost(sink: LooshSink) -> u128 {
    match sink {
        LooshSink::CreateGalaxy => 1000,
        LooshSink::CreateProtostar => 100,
        LooshSink::FormStar => 20,
        LooshSink::CreateAsteroidCluster => 10,
    }
}
