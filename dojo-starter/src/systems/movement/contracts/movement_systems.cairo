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
    use dojo_starter::models::{
        position::Position, vec2::{Vec2, Vec2Impl}, travel_action::TravelAction, orbit::Orbit,
        cosmic_body::{CosmicBody, CosmicBodyType}
    };
    use dojo_starter::systems::{
        loosh::contracts::loosh_systems::loosh_systems::{InternalLooshSystemsImpl}
    };

    // Structure to represent a BodyMoved event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct BodyMoved {
        #[key]
        body_id: u32,
        new_x: u64,
        new_y: u64,
    }

    // Structure to represent a BodyEnteredOrbit event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct BodyEnteredOrbit {
        #[key]
        body_id: u32,
        orbit_center: u32,
    }

    // Structure to represent a BodyExitedOrbit event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct BodyExitedOrbit {
        #[key]
        body_id: u32,
        orbit_center: u32,
    }

    // Structure to represent a BodiesCollided event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct BodiesCollided {
        #[key]
        body_id: u32,
        target_id: u32,
        mass_change_body: i64, // Change in mass after the collision
        mass_change_target: i64,
    }

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
            let body_position = get!(world, body_id, (Position));
            assert(body_position.vec.is_equal(target_position) == false, 'already at target pos');

            let body_orbit = get!(world, body_id, (Orbit));
            assert(body_orbit.orbit_center == 0, 'body in an orbit');

            let body_type = get!(world, body_id, (CosmicBody));
            assert(body_type.body_type == CosmicBodyType::AsteroidCluster, 'body type cant travel');

            let player = get_caller_address();
            let distance = target_position.chebyshev_distance(body_position.vec);
            InternalLooshSystemsImpl::spend_loosh_for_travel(world, player, distance);

            let depart_ts = get_block_timestamp();
            let seconds_per_coordinate = 60 * 15;
            let total_travel_time = seconds_per_coordinate * distance;
            let arrival_ts = depart_ts + total_travel_time;
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
            let body_orbit = get!(world, body_id, (Orbit));
            assert(body_orbit.orbit_center == 0, 'already in an orbit');

            let orbit_center_body = get!(world, orbit_center, CosmicBody);
            assert(orbit_center_body.body_type == CosmicBodyType::Star, 'cannot orbit body type');

            let body_position = get!(world, body_id, (Position));
            let orbit_center_position = get!(world, orbit_center, (Position));
            assert(body_position.vec.is_equal(orbit_center_position.vec), 'not in proximity');

            set!(world, (Orbit { entity: body_id, orbit_center }));
        }

        fn exit_orbit(world: IWorldDispatcher, body_id: u32) {
            let body_orbit = get!(world, body_id, (Orbit));
            assert(body_orbit.orbit_center != 0, 'not in an orbit');

            delete!(world, (body_orbit));
        }
    }
}
