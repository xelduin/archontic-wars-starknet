use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IHarvestSystems<T> {
    fn start_harvest(ref self: T, asteroid_id: u32, dust_cloud_id: u32, amount: u128);
    fn end_harvest(ref self: T, asteroid_id: u32);
    fn cancel_harvest(ref self: T, asteroid_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod harvest_systems {
    use super::{IHarvestSystems};
    use starknet::{ContractAddress, get_caller_address};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::WorldStorage;

    use astraplani::operators;

    use astraplani::validators::owner::assert_is_owner;
    use astraplani::validators::action_status::assert_is_idle;
    use astraplani::validators::map::assert_entities_at_same_coords;
    use astraplani::validators::harvest::assert_has_dust_balance;
    use astraplani::validators::harvest::assert_can_carry_dust;

    use astraplani::models::harvest_action::HarvestParams;
    use astraplain::models::action_status::ActionParams;

    #[abi(embed_v0)]
    impl HarvestSystemsImpl of IHarvestSystems<ContractState> {
        fn start_harvest(
            ref self: ContractState, asteroid_id: u32, dust_cloud_id: u32, amount: u128
        ) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());
            assert_is_idle(world, asteroid_id);
            assert_entities_at_same_coords(world, asteroid_id, dust_cloud_id);
            assert_has_dust_balance(world, params.dust_cloud_id, params.amount);
            assert_can_carry_dust(world, asteroid_id, params.amount);

            let harvest_params = HarvestParams { dust_cloud_id, amount };
            let action_params = ActionParams::Harvest(harvest_params);

            operations::action::start_action(world, asteroid_id, params);
        }

        fn end_harvest(ref self: ContractState, asteroid_id: u32) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());

            operations::action::end_action(world, asteroid_id);
        }

        fn cancel_harvest(ref self: ContractState, asteroid_id: u32) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());

            operations::action::cancel_action(world, asteroid_id);
        }
    }
}
