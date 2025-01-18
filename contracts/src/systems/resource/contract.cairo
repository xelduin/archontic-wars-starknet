use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IDustSystems<T> {
    fn transfer_dust(ref self: T, sender_id: u32, receiver_id: u32, amount: u128);
}

// Dojo decorator
#[dojo::contract]
mod dust_systems {
    use super::{IDustSystems};
    use starknet::{ContractAddress, get_caller_address};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::WorldStorage;

    use astraplani::models::owner::Owner;
    use astraplani::models::Vec2;
    use astraplani::models::GridCell;
    use astraplani::models::DustBalance;

    use astraplani::validators::owner::assert_is_owner;
    use astraplani::validators::action_status::assert_is_idle;
    use astraplani::validators::dust::assert_has_dust_balance;
    use astraplani::validators::dust::assert_can_carry_dust;


    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct DustTransferred {
        #[key]
        sender_id: u32,
        receiver_id: u32,
        amount: u128
    }

    #[abi(embed_v0)]
    impl DustSystemsImpl of IDustSystems<ContractState> {
        fn transfer_dust(ref self: ContractState, sender_id: u32, receiver_id: u32, amount: u128) {
            let mut world = self.world(@"ns");
            assert_is_owner(world, sender_id);
            assert_is_idle(world, sender_id);
            assert_has_dust_balance(world, sender_id);
            assert_can_carry_dust(world, receiver_id);
            //update_sender_balance
        //update_receiver_balance
        //emit_event
        }
    }
}
