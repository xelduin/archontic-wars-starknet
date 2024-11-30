use starknet::{ContractAddress};
use dojo::world::IWorldDispatcher;
use astraplani::models::loosh_sink::LooshSink;

// Define the interface
#[starknet::interface]
trait ILooshSystems<T> {
    fn l1_receive_loosh(ref self: T, receiver: ContractAddress, amount: u128);
    fn transfer_loosh(ref self: T, receiver: ContractAddress, amount: u128);
    fn burn_loosh(ref self: T, amount: u128);
}

// Dojo decorator
#[dojo::contract]
mod loosh_systems {
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    use super::{ILooshSystems};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    use astraplani::models::owner::Owner;
    use astraplani::models::loosh_balance::LooshBalance;
    use astraplani::models::{loosh_sink::LooshSink};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct LooshTransferred {
        #[key]
        sender: ContractAddress,
        receiver: ContractAddress,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct LooshBurned {
        #[key]
        sender: ContractAddress,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct LooshMinted {
        #[key]
        receiver: ContractAddress,
        amount: u128,
    }

    #[abi(embed_v0)]
    impl LooshSystemsImpl of ILooshSystems<ContractState> {
        fn l1_receive_loosh(ref self: ContractState, receiver: ContractAddress, amount: u128,) {
            let mut world = self.world(@"ns");
            InternalLooshSystemsImpl::mint_loosh(world, receiver, amount);
        }

        fn transfer_loosh(ref self: ContractState, receiver: ContractAddress, amount: u128,) {
            let mut world = self.world(@"ns");
            let sender = get_caller_address();

            InternalLooshSystemsImpl::transfer_loosh(world, sender, receiver, amount);
        }

        fn burn_loosh(ref self: ContractState, amount: u128,) {
            let mut world = self.world(@"ns");
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
            let current_sender_balance : LooshBalance = world.read_model(sender);

            assert(current_sender_balance.balance >= amount, 'insufficient balance');

            let new_sender_balance = current_sender_balance.balance - amount;

            let current_receiver_balance : LooshBalance = world.read_model(receiver);
            let new_receiver_balance = current_receiver_balance.balance + amount;

            world.write_model(@(
                    LooshBalance { address: sender, balance: new_sender_balance },
                    LooshBalance { address: receiver, balance: new_receiver_balance }
                )
            );
            world.emit_event(@(LooshTransferred { sender, receiver, amount }));
        }

        fn mint_loosh(world: IWorldDispatcher, receiver: ContractAddress, amount: u128,) {
            let current_loosh_balance : LooshBalance = world.read_model(receiver);

            world.write_model(@(LooshBalance {
                    address: receiver, balance: current_loosh_balance.balance + amount
                })
            );
            world.emit_event(@(LooshMinted { receiver, amount }));
        }

        fn burn_loosh(world: IWorldDispatcher, address: ContractAddress, amount: u128,) {
            let loosh_balance : LooshBalance = world.read_model(address);
            assert(loosh_balance.balance >= amount, 'insufficient loosh');
            let new_balance = loosh_balance.balance - amount;
            world.write_model(@(LooshBalance { address, balance: new_balance }));
            world.emit_event(@LooshBurned { sender: address, amount });
        }

        fn spend_loosh(world: IWorldDispatcher, spender: ContractAddress, cost: u128) {
            Self::burn_loosh(world, spender, cost);
        }
    }
}
