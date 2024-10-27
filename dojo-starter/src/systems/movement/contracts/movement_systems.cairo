use dojo_starter::models::vec2::Vec2;

// Define the interface for the Body movement system
#[dojo::interface]
trait IMovementSystems {
    fn begin_travel(ref world: IWorldDispatcher, body_id: u32, target_position: Vec2);
    fn end_travel(ref world: IWorldDispatcher, body_id: u32);
    fn enter_orbit(ref world: IWorldDispatcher, body_id: u32, orbit_center: u32);
    fn exit_orbit(ref world: IWorldDispatcher, body_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod movement_systems {
    use super::IMovementSystems;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::utils::travel_helpers::{get_arrival_ts, get_loosh_travel_cost};

    use dojo_starter::systems::loosh::contracts::loosh_systems::loosh_systems::InternalLooshSystemsImpl;

    use dojo_starter::models::position::{Position, PositionCustomImpl};
    use dojo_starter::models::vec2::{Vec2, Vec2Impl};
    use dojo_starter::models::travel_action::TravelAction;
    use dojo_starter::models::orbit::Orbit;
    use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use dojo_starter::models::dust_accretion::DustAccretion;
    use dojo_starter::models::orbital_mass::OrbitalMass;
    use dojo_starter::models::mass::Mass;

    #[abi(embed_v0)]
    impl MovementSystemsImpl of IMovementSystems<ContractState> {
        fn begin_travel(ref world: IWorldDispatcher, body_id: u32, target_position: Vec2) {
            InternalMovementSystemsImpl::begin_travel(world, body_id, target_position);
        }

        fn end_travel(ref world: IWorldDispatcher, body_id: u32) {
            InternalMovementSystemsImpl::end_travel(world, body_id);
        }

        fn enter_orbit(ref world: IWorldDispatcher, body_id: u32, orbit_center: u32) {
            InternalMovementSystemsImpl::enter_orbit(world, body_id, orbit_center);
        }

        fn exit_orbit(ref world: IWorldDispatcher, body_id: u32) {
            InternalMovementSystemsImpl::exit_orbit(world, body_id);
        }
    }

    #[generate_trait]
    impl InternalMovementSystemsImpl of InternalMovementSystemsTrait {
        fn begin_travel(world: IWorldDispatcher, body_id: u32, target_position: Vec2) {
            let body_travel = get!(world, body_id, TravelAction);
            assert(body_travel.arrival_ts == 0, 'body already travelling');

            let body_position = get!(world, body_id, (Position));
            assert(body_position.vec.is_equal(target_position) == false, 'already at target pos');

            let body_type = get!(world, body_id, (CosmicBody));
            assert(body_type.body_type == CosmicBodyType::AsteroidCluster, 'body type cant travel');

            let body_orbit = get!(world, body_id, Orbit);
            let orbit_center_body = get!(world, body_orbit.orbit_center, CosmicBody);

            let player = get_caller_address();
            let travel_cost = get_loosh_travel_cost(
                world, body_position.vec, target_position, orbit_center_body.body_type
            );
            InternalLooshSystemsImpl::spend_loosh(world, player, travel_cost);

            let depart_ts = get_block_timestamp();
            let arrival_ts = get_arrival_ts(
                world, depart_ts, body_position.vec, target_position, orbit_center_body.body_type
            );

            set!(world, (TravelAction { entity: body_id, depart_ts, arrival_ts, target_position }));
        }

        fn end_travel(world: IWorldDispatcher, body_id: u32) {
            let travel_action = get!(world, body_id, (TravelAction));
            let current_ts = get_block_timestamp();

            assert(travel_action.arrival_ts != 0, 'invalid travel action');
            assert(current_ts >= travel_action.arrival_ts, 'not arrived');

            set!(world, (Position { entity: body_id, vec: travel_action.target_position }));

            delete!(world, (travel_action));
        }

        fn enter_orbit(world: IWorldDispatcher, body_id: u32, orbit_center: u32) {
            let body_travel = get!(world, body_id, TravelAction);
            assert(body_travel.arrival_ts == 0, 'body is travelling');

            let body_body = get!(world, body_id, CosmicBody);
            assert(
                body_body.body_type == CosmicBodyType::AsteroidCluster,
                'body type cannot enter orbit'
            );

            let orbit_center_body = get!(world, orbit_center, CosmicBody);
            assert(
                orbit_center_body.body_type != CosmicBodyType::AsteroidCluster,
                'cannot orbit body type'
            );

            let body_position = get!(world, body_id, (Position));
            let orbit_center_position = get!(world, orbit_center, (Position));
            assert(body_position.is_equal(world, orbit_center_position), 'not in proximity');

            let orbit_center_orbital_mass = get!(world, orbit_center, OrbitalMass);
            let body_mass = get!(world, body_id, Mass);
            set!(
                world,
                (
                    OrbitalMass {
                        entity: orbit_center,
                        orbital_mass: orbit_center_orbital_mass.orbital_mass + body_mass.mass
                    },
                    Orbit { entity: body_id, orbit_center },
                    Position { entity: body_id, vec: Vec2 { x: 1, y: 1 } }
                )
            );
        }

        fn exit_orbit(world: IWorldDispatcher, body_id: u32) {
            let body_orbit = get!(world, body_id, (Orbit));
            assert(body_orbit.orbit_center != 0, 'not in an orbit');

            let body_body = get!(world, body_id, CosmicBody);
            assert(
                body_body.body_type == CosmicBodyType::AsteroidCluster,
                'body type cannot exit orbit'
            );

            let body_accretion = get!(world, body_id, DustAccretion);
            assert(body_accretion.in_dust_pool == false, 'must exit dust pool');

            let orbit_center_orbit = get!(world, body_orbit.orbit_center, Orbit);
            let orbit_center_position = get!(world, body_orbit.orbit_center, Position);
            let orbit_center_orbital_mass = get!(world, body_orbit.orbit_center, OrbitalMass);
            let body_mass = get!(world, body_id, Mass);
            set!(
                world,
                (
                    OrbitalMass {
                        entity: body_id,
                        orbital_mass: orbit_center_orbital_mass.orbital_mass - body_mass.mass
                    },
                    Orbit { entity: body_id, orbit_center: orbit_center_orbit.orbit_center },
                    Position { entity: body_id, vec: orbit_center_position.vec }
                )
            )
        }
    }
}
