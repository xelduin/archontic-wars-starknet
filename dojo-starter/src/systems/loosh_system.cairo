use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;
use dojo_starter::models::loosh_sink::LooshSink;

// Define the interface
#[dojo::interface]
trait ILooshSystem {
    fn l1_receive_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128);
    fn send_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128);
    fn burn_loosh(ref world: IWorldDispatcher, amount: u128);
    fn reference_archetype(ref world: IWorldDispatcher, archetype_id: u32);
    fn get_archetype_reference_cost(ref world: IWorldDispatcher, archetype_id: u32) -> u128;
}

// Dojo decorator
#[dojo::contract]
mod loosh_system {
    use super::{ILooshSystem, get_loosh_cost};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};
    use dojo_starter::models::loosh_balance::LooshBalance;
    use dojo_starter::models::owner::Owner;
    use dojo_starter::models::{loosh_sink::LooshSink};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    struct LooshTransferred {
        #[key]
        sender: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    #[dojo::model]
    struct LooshMinted {
        #[key]
        receiver: ContractAddress,
        amount: u128,
    }

    #[abi(embed_v0)]
    impl LooshSystemImpl of ILooshSystem<ContractState> {
        fn l1_receive_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            // Check that the incoming message comes from the authorized L1 contract
            InternalLooshSystemImpl::mint_loosh(world, receiver, amount);
        }

        fn send_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            let sender = get_caller_address();

            InternalLooshSystemImpl::transfer_loosh(world, sender, receiver, amount);
        }

        fn burn_loosh(ref world: IWorldDispatcher, amount: u128,) {
            let sender = get_caller_address();

            InternalLooshSystemImpl::burn_loosh(world, sender, amount);
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

        fn mint_loosh(world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            // Check that the incoming message comes from the authorized L1 contract
            let current_loosh_balance = get!(world, receiver, (LooshBalance));

            set!(
                world,
                (LooshBalance {
                    address: receiver, balance: current_loosh_balance.balance + amount
                })
            );
            emit!(world, (LooshMinted { receiver, amount }));
        }

        fn burn_loosh(world: IWorldDispatcher, address: ContractAddress, amount: u128,) {
            Self::transfer_loosh(world, address, get_contract_address(), amount);
        }


        fn spend_loosh(world: IWorldDispatcher, spender: ContractAddress, sink: LooshSink) {
            let cost = get_loosh_cost(sink);
            Self::burn_loosh(world, spender, cost);
        }

        fn spend_loosh_for_travel(
            world: IWorldDispatcher, spender: ContractAddress, distance: u64
        ) {
            let cost = distance.try_into().unwrap() * 5_u128;
            Self::burn_loosh(world, spender, cost);
        }
    }
}

fn get_loosh_cost(sink: LooshSink) -> u128 {
    match sink {
        LooshSink::CreateGalaxy => 1000,
        LooshSink::CreateProtostar => 100,
        LooshSink::FormStar => 20,
        LooshSink::CreateAsteroidCluster => 10,
    }
}
