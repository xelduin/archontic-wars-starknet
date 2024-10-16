use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;
use dojo_starter::models::loosh_sink::LooshSink;

// Define the interface
#[dojo::interface]
trait ILooshSystems {
    fn l1_receive_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128);
    fn transfer_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128);
    fn burn_loosh(ref world: IWorldDispatcher, amount: u128);
}

// Dojo decorator
#[dojo::contract]
mod loosh_systems {
    use super::{ILooshSystems, get_loosh_cost};
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
    impl LooshSystemsImpl of ILooshSystems<ContractState> {
        fn l1_receive_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            // Check that the incoming message comes from the authorized L1 contract
            InternalLooshSystemsImpl::mint_loosh(world, receiver, amount);
        }

        fn transfer_loosh(ref world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            let sender = get_caller_address();

            InternalLooshSystemsImpl::transfer_loosh(world, sender, receiver, amount);
        }

        fn burn_loosh(ref world: IWorldDispatcher, amount: u128,) {
            let sender = get_caller_address();

            InternalLooshSystemsImpl::burn_loosh(world, sender, amount);
        }
    }

    #[generate_trait]
    pub impl InternalLooshSystemsImpl of InternalLooshSystemsTrait {
        fn transfer_loosh(
            world: IWorldDispatcher,
            sender: ContractAddress,
            receiver: ContractAddress,
            amount: u128
        ) {
            let current_sender_balance = get!(world, sender, (LooshBalance));

            assert(current_sender_balance.balance >= amount, 'insufficient balance');

            let new_sender_balance = current_sender_balance.balance - amount;

            let current_receiver_balance = get!(world, receiver, (LooshBalance));
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
            let loosh_balance = get!(world, address, LooshBalance);
            assert(loosh_balance.balance >= amount, 'insufficient loosh');
            let new_balance = loosh_balance.balance - amount;
            set!(world, (LooshBalance { address, balance: new_balance }));
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
