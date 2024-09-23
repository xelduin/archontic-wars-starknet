use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;

// Define the interface
#[dojo::interface]
trait ILooshSystem {
    fn send_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128);
    fn consume_loosh(ref world: IWorldDispatcher, amount: u128);
    fn reference_archetype(ref world: IWorldDispatcher, archetype_id: u32);
    fn get_archetype_reference_cost(ref world: IWorldDispatcher, archetype_id: u32) -> u128;
}

// Dojo decorator
#[dojo::contract]
mod loosh_system {
    use super::ILooshSystem;
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use dojo_starter::models::loosh_balance::LooshBalance;
    use dojo_starter::models::owner::Owner;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    struct LooshTransferred {
        #[key]
        sender: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
    }

    #[abi(embed_v0)]
    impl LooshSystemImpl of ILooshSystem<ContractState> {
        fn send_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            let sender = get_caller_address();

            InternalLooshSystemImpl::transfer_loosh(world, sender, receiver, amount);
        }

        fn consume_loosh(ref world: IWorldDispatcher, amount: u128,) {
            let sender = get_caller_address();

            InternalLooshSystemImpl::transfer_loosh(world, sender, get_contract_address(), amount);
        }


        fn reference_archetype(
            ref world: IWorldDispatcher, archetype_id: u32
        ) { // Get the cost for referencing an archetype
            let sender = get_caller_address();

            let owner = get!(world, archetype_id, (Owner));
            // 1. Call get_archetype_reference_cost(archetype_id) to get cost.
            let cost = 0;

            InternalLooshSystemImpl::transfer_loosh(world, sender, owner.address, cost);
        }

        fn get_archetype_reference_cost(
            ref world: IWorldDispatcher, archetype_id: u32,
        ) -> u128 { // Return the cost in Loosh for referencing the specified archetype
            // 1. Lookup the cost from predefined archetype data.
            // return cost;
            let archetype_reference_cost = 0;

            if archetype_id == 0 {
                return 0;
            } else {
                return archetype_reference_cost;
            }
        }
    }

    #[generate_trait]
    pub impl InternalLooshSystemImpl of InternalLooshSystemTrait {
        fn transfer_loosh(
            world: IWorldDispatcher,
            sender: ContractAddress,
            receiver: ContractAddress,
            amount: u128
        ) {
            let current_sender_balance = get!(world, sender, (LooshBalance));

            assert(current_sender_balance.balance >= amount, 'not enough Loosh');
            let new_sender_balance = current_sender_balance.balance - amount;

            let current_receiver_balance = get!(world, sender, (LooshBalance));
            let new_receiver_balance = current_receiver_balance.balance + amount;

            set!(
                world,
                (
                    LooshBalance { address: sender, balance: new_sender_balance },
                    LooshBalance { address: receiver, balance: new_receiver_balance }
                )
            );

            emit!(world, (LooshTransferred { sender, receiver, amount }));
        }
    }
}

