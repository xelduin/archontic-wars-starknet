use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait ITravelSystems<T> {
    fn start_travel(ref self: T, asteroid_id: u32, target_coords: Vec2);
    fn end_travel(ref self: T, asteroid_id: u32);
    fn cancel_travel(ref self: T, asteroid_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod travel_systems {
    use super::{ITravelSystems};
    use starknet::{ContractAddress, get_caller_address};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::WorldStorage;

    use astraplani::operations;

    use astraplani::utils::travel::get_pneuma_travel_cost;
    use astraplani::utils::map::get_current_position;

    use astraplani::validators::owner::assert_is_owner;
    use astraplani::validators::action::assert_is_idle;
    use astraplani::validators::map::assert_not_at_coords;
    use astraplani::validators::pneuma::assert_has_pneuma_balance;

    use astraplani::models::action_status::ActionParams;
    use astraplani::models::travel_action::TravelParams;
    use astraplani::models::vec2::Vec2;

    #[abi(embed_v0)]
    impl TravelSystemsImpl of ITravelSystems<ContractState> {
        fn start_travel(ref self: ContractState, asteroid_id: u32, target_coords: Vec2) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());
            assert_is_idle(world, asteroid_id);
            assert_not_at_coords(world, asteroid_id, target_coords);

            let pneuma_cost = get_pneuma_travel_cost(world, asteroid_id, target_coords);
            assert_has_pneuma_balance(get_caller_address(), pneuma_cost);

            let travel_params = TravelParams {
                start_coords: get_current_position(world, asteroid_id), target_coords
            };
            let action_params = ActionParams::Travel(travel_params);

            operations::action::start_action(world, asteroid_id, action_params);
        }

        fn end_travel(ref self: ContractState, asteroid_id: u32) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());

            operations::action::end_action(world, asteroid_id);
        }

        fn cancel_travel(ref self: ContractState, asteroid_id: u32) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());

            operations::action::cancel_action(world, asteroid_id);
        }
    }
}
