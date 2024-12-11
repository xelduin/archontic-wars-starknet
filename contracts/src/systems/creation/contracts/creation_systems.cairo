use starknet::{ContractAddress, get_caller_address};
use astraplani::models::vec2::Vec2;

// Define the interface for the Body creation system
#[starknet::interface]
trait ICreationSystems<T> {
    fn create_quasar(ref self: T, coords: Vec2) -> u32;
    fn create_protostar(ref self: T, coords: Vec2, quasar_id: u32) -> u32;
    fn create_asteroid_cluster(ref self: T, star_id: u32) -> u32;
    fn form_star(ref self: T, protostar_id: u32);
    fn form_asteroids(ref self: T, star_id: u32, cluster_id: u32, amount: u64);
}

// Dojo decorator
#[dojo::contract]
mod creation_systems {
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::IWorldDispatcherTrait;

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
    use astraplani::models::position::{Position, OrbitCenterAtPosition, PositionCustomImpl};
    use astraplani::models::orbit::Orbit;
    use astraplani::models::orbital_mass::OrbitalMass;
    use astraplani::models::mass::Mass;
    use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use astraplani::models::incubation::Incubation;
    use astraplani::models::loosh_sink::LooshSink;
    use astraplani::models::basal_attributes::BasalAttributes;

    #[derive(Copy, Drop, Serde)]
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
    #[dojo::event]
    struct StarFormed {
        #[key]
        body_id: u32,
        creation_ts: u64,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct AsteroidsFormed {
        #[key]
        body_id: u32,
        mass: u64,
        creation_ts: u64,
    }

    #[abi(embed_v0)]
    impl CreationSystemsImpl of ICreationSystems<ContractState> {
        fn create_quasar(ref self: ContractState, coords: Vec2) -> u32 {
            let mut world = self.world(@"ns");
            return InternalCreationSystemsImpl::create_quasar(world, coords);
        }

        fn create_protostar(ref self: ContractState, coords: Vec2, quasar_id: u32) -> u32 {
            let mut world = self.world(@"ns");
            return InternalCreationSystemsImpl::create_protostar(world, coords, quasar_id);
        }

        fn create_asteroid_cluster(ref self: ContractState, star_id: u32) -> u32 {
            let mut world = self.world(@"ns");
            return InternalCreationSystemsImpl::create_asteroid_cluster(
                world, star_id, initial_mass: 100
            );
        }

        fn form_star(ref self: ContractState, protostar_id: u32) {
            let mut world = self.world(@"ns");
            InternalCreationSystemsImpl::form_star(world, protostar_id);
        }

        fn form_asteroids(ref self: ContractState, star_id: u32, cluster_id: u32, amount: u64) {
            let mut world = self.world(@"ns");
            InternalCreationSystemsImpl::form_asteroids(world, star_id, cluster_id, amount);
        }
    }

    #[generate_trait]
    impl InternalCreationSystemsImpl of InternalCreationSystemsTrait {
        fn create_quasar(mut world: WorldStorage, coords: Vec2) -> u32 {
            assert_caller_is_admin(world);

            let central_entity_at_pos: OrbitCenterAtPosition = world
                .read_model((coords.x, coords.y, 0));
            assert(central_entity_at_pos.entity_id == 0, 'coords are occupied');

            let player = get_caller_address();
            let loosh_cost = get_loosh_cost(LooshSink::CreateQuasar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.dispatcher.uuid();
            let universe_id = 0;
            let body_mass_config: BaseCosmicBodyMassConfig = world
                .read_model(COSMIC_BODY_MASS_CONFIG_ID);
            let mass = body_mass_config.base_quasar_mass;
            Self::create_cosmic_body(
                world, player, body_id, CosmicBodyType::Quasar, mass, universe_id, coords,
            );

            world
                .write_model(
                    @(OrbitCenterAtPosition {
                        x: coords.x, y: coords.y, orbit_center: universe_id, entity_id: body_id
                    })
                );
            world
                .emit_event(
                    @QuasarCreated {
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

        fn create_protostar(mut world: WorldStorage, coords: Vec2, quasar_id: u32) -> u32 {
            let quasar_body: CosmicBody = world.read_model(quasar_id);
            assert(quasar_body.body_type == CosmicBodyType::Quasar, 'invalid quasar id');

            let central_entity_at_pos: OrbitCenterAtPosition = world
                .read_model((coords.x, coords.y, quasar_id));
            assert(central_entity_at_pos.entity_id == 0, 'coords are occupied');

            let player = get_caller_address();
            let loosh_cost = get_loosh_cost(LooshSink::CreateProtostar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let body_id = world.dispatcher.uuid();
            let body_mass_config: BaseCosmicBodyMassConfig = world
                .read_model(COSMIC_BODY_MASS_CONFIG_ID);
            let mass = body_mass_config.base_star_mass;
            Self::create_cosmic_body(
                world, player, body_id, CosmicBodyType::Protostar, mass, quasar_id, coords,
            );

            let creation_ts = get_block_timestamp();
            let incubation_config: IncubationTimeConfig = world
                .read_model(INCUBATION_TIME_CONFIG_ID);
            let incubation_period = incubation_config.base_incubation_time;
            let incubation_end_ts = creation_ts + incubation_period;
            let attributes = 20;

            let new_incubation = Incubation {
                entity_id: body_id, creation_ts, end_ts: incubation_end_ts
            };
            let new_orbit_center_at_position = OrbitCenterAtPosition {
                x: coords.x, y: coords.y, orbit_center: quasar_id, entity_id: body_id
            };
            let new_basal_attributes = BasalAttributes { entity_id: body_id, attributes };

            world.write_model(@new_incubation);
            world.write_model(@new_orbit_center_at_position);
            world.write_model(@new_basal_attributes);

            world
                .emit_event(
                    @(ProtostarCreated {
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
            mut world: WorldStorage, star_id: u32, initial_mass: u64
        ) -> u32 {
            let star_body: CosmicBody = world.read_model(star_id);
            assert(star_body.body_type == CosmicBodyType::Star, 'invalid star id');

            let player = get_caller_address();
            let star_owner: Owner = world.read_model(star_id);
            assert(star_owner.address == player, 'caller must own star');

            let loosh_cost = get_loosh_cost(LooshSink::CreateAsteroidCluster);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            let star_orbit: Orbit = world.read_model(star_id);
            let quasar_id = star_orbit.orbit_center;

            let star_position: Position = world.read_model(star_id);

            let body_id = world.dispatcher.uuid();
            Self::create_cosmic_body(
                world,
                player,
                body_id,
                CosmicBodyType::AsteroidCluster,
                initial_mass,
                quasar_id,
                star_position.vec,
            );

            world
                .emit_event(
                    @AsteroidClusterCreated {
                        body_id,
                        owner: player,
                        mass: initial_mass,
                        coords: star_position.vec,
                        parent_id: star_id,
                        creation_ts: get_block_timestamp(),
                    }
                );

            return body_id;
        }

        fn create_cosmic_body(
            mut world: WorldStorage,
            owner: ContractAddress,
            body_id: u32,
            body_type: CosmicBodyType,
            mass: u64,
            orbit_center: u32,
            coords: Vec2,
        ) {
            let orbit_center_orbital_mass: OrbitalMass = world.read_model(orbit_center);

            let new_cosmic_body = CosmicBody { entity_id: body_id, body_type };
            let new_position = Position { entity_id: body_id, vec: coords };
            let new_orbit = Orbit { entity_id: body_id, orbit_center };
            let new_mass = Mass { entity_id: body_id, mass };
            let new_orbital_mass = OrbitalMass {
                entity_id: orbit_center, orbital_mass: orbit_center_orbital_mass.orbital_mass + mass
            };
            let new_owner = Owner { entity_id: body_id, address: owner };

            world.write_model(@new_cosmic_body);
            world.write_model(@new_position);
            world.write_model(@new_orbit);
            world.write_model(@new_mass);
            world.write_model(@new_orbital_mass);
            world.write_model(@new_owner);
            //world.emit_event
        }

        fn form_star(mut world: WorldStorage, protostar_id: u32) {
            let player = get_caller_address();
            let protostar_owner: Owner = world.read_model(protostar_id);
            assert(protostar_owner.address == player, 'caller must be owner');

            let protostar_body: CosmicBody = world.read_model(protostar_id);
            assert(protostar_body.body_type == CosmicBodyType::Protostar, 'invalid protostar id');

            let protostar_incubation: Incubation = world.read_model(protostar_id);
            let current_ts = get_block_timestamp();
            assert(current_ts >= protostar_incubation.end_ts, 'incubation not over');

            let loosh_cost = get_loosh_cost(LooshSink::FormStar);
            InternalLooshSystemsImpl::spend_loosh(world, player, loosh_cost);

            world
                .write_model(
                    @(CosmicBody { entity_id: protostar_id, body_type: CosmicBodyType::Star })
                );
            world.erase_model(@protostar_incubation);

            world.emit_event(@(StarFormed { body_id: protostar_id, creation_ts: current_ts }));
        }

        fn form_asteroids(mut world: WorldStorage, star_id: u32, cluster_id: u32, mass: u64) {
            let player = get_caller_address();
            let star_owner: Owner = world.read_model(star_id);
            assert(star_owner.address == player, 'caller must own star');

            let star_body: CosmicBody = world.read_model(star_id);
            assert(star_body.body_type == CosmicBodyType::Star, 'invalid star id');

            let asteroid_cluster_body: CosmicBody = world.read_model(cluster_id);
            assert(
                asteroid_cluster_body.body_type == CosmicBodyType::AsteroidCluster,
                'invalid asteroid cluster id'
            );

            let star_position: Position = world.read_model(star_id);
            let asteroid_cluster_position: Position = world.read_model(cluster_id);
            assert(
                star_position.is_equal(world, asteroid_cluster_position), 'asteroid cluster too far'
            );

            let dust_value_config: DustValueConfig = world.read_model(DUST_VALUE_CONFIG_ID);
            let mass_to_dust = dust_value_config.mass_to_dust;
            let dust_to_consume = mass_to_dust * mass.try_into().unwrap();

            InternalDustSystemsImpl::consume_dust(world, star_id, dust_to_consume);
            InternalMassSystemsImpl::increase_mass(world, cluster_id, mass);

            world
                .emit_event(
                    @(AsteroidsFormed {
                        body_id: cluster_id, mass, creation_ts: get_block_timestamp()
                    })
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
