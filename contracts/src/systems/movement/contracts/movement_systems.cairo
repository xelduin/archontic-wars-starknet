use astraplani::models::vec2::Vec2;

// Define the interface for the Body movement system
#[dojo::interface]
trait IMovementSystems {
    fn begin_travel(ref world: IWorldDispatcher, body_id: u32, target_position: Vec2);
    fn end_travel(ref world: IWorldDispatcher, body_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod movement_systems {
    use super::IMovementSystems;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use astraplani::utils::travel_helpers::{get_arrival_ts, get_loosh_travel_cost};

    use astraplani::systems::loosh::contracts::loosh_systems::loosh_systems::InternalLooshSystemsImpl;

    use astraplani::models::position::{Position, PositionCustomImpl};
    use astraplani::models::vec2::{Vec2, Vec2Impl};
    use astraplani::models::travel_action::TravelAction;
    use astraplani::models::orbit::Orbit;
    use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct TravelBegan {
        #[key]
        body_id: u32,
        origin_vec: Vec2,
        target_vec: Vec2,
        arrival_ts: u64
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct TravelEnded {
        #[key]
        body_id: u32,
        arrival_ts: u64
    }


    #[abi(embed_v0)]
    impl MovementSystemsImpl of IMovementSystems<ContractState> {
        fn begin_travel(ref world: IWorldDispatcher, body_id: u32, target_position: Vec2) {
            InternalMovementSystemsImpl::begin_travel(world, body_id, target_position);
        }

        fn end_travel(ref world: IWorldDispatcher, body_id: u32) {
            InternalMovementSystemsImpl::end_travel(world, body_id);
        }
    }

    #[generate_trait]
    impl InternalMovementSystemsImpl of InternalMovementSystemsTrait {
        fn begin_travel(world: IWorldDispatcher, body_id: u32, target_position: Vec2) {
            let cur_travel_action = get!(world, body_id, TravelAction);
            assert(cur_travel_action.arrival_ts == 0, 'body already travelling');

            let body_position = get!(world, body_id, (Position));
            assert(body_position.vec.is_equal(target_position) == false, 'already at target pos');

            let traveler_body_type = get!(world, body_id, (CosmicBody)).body_type;
            assert(traveler_body_type == CosmicBodyType::AsteroidCluster, 'body type cant travel');

            let orbit_center_id = get!(world, body_id, Orbit).orbit_center;
            let orbit_center_body_type = get!(world, orbit_center_id, CosmicBody).body_type;

            let player = get_caller_address();
            let travel_cost = get_loosh_travel_cost(
                world, body_position.vec, target_position, orbit_center_body_type
            );
            InternalLooshSystemsImpl::spend_loosh(world, player, travel_cost);

            let depart_ts = get_block_timestamp();
            let arrival_ts = get_arrival_ts(
                world, depart_ts, body_position.vec, target_position, orbit_center_body_type
            );

            set!(world, (TravelAction { entity: body_id, depart_ts, arrival_ts, target_position }));
            emit!(
                world,
                (TravelBegan {
                    body_id, origin_vec: body_position.vec, target_vec: target_position, arrival_ts
                })
            );
        }

        fn end_travel(world: IWorldDispatcher, body_id: u32) {
            let cur_travel_action = get!(world, body_id, (TravelAction));
            let current_ts = get_block_timestamp();

            assert(cur_travel_action.arrival_ts != 0, 'invalid travel action');
            assert(current_ts >= cur_travel_action.arrival_ts, 'not arrived');

            set!(world, (Position { entity: body_id, vec: cur_travel_action.target_position }));

            delete!(world, (cur_travel_action));

            emit!(world, (TravelEnded { body_id, arrival_ts: current_ts }));
        }
    }
}
