use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IAuthoritySystems<T> {
    fn transfer_ownership(ref self: T, body_id: u32, new_owner: ContractAddress);
}

// Dojo decorator
#[dojo::contract]
mod authority_systems {
    use super::{IAuthoritySystems};
    use starknet::{ContractAddress, get_caller_address};

    use astraplani::models::owner::Owner;

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct OwnershipTransferred {
        #[key]
        body_id: u32,
        new_owner: ContractAddress,
    }

    #[abi(embed_v0)]
    impl AuthoritySystemsImpl of IAuthoritySystems<ContractState> {
        fn transfer_ownership(ref self: ContractState, body_id: u32, new_owner: ContractAddress) {
            let mut world = self.world(@"ns");

            let caller = get_caller_address();
            let ownership: Owner = world.read_model(body_id);

            assert(caller == ownership.address, 'not owner');

            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, new_owner);
        }
    }

    #[generate_trait]
    impl InternalAuthoritySystemsImpl of InternalAuthoritySystemsTrait {
        fn transfer_ownership(
            mut world: IWorldDispatcher, body_id: u32, new_owner: ContractAddress
        ) {
            world.write_model(@Owner { entity: body_id, address: new_owner });
            world.emit_event(@OwnershipTransferred { body_id, new_owner });
        }
    }
}
