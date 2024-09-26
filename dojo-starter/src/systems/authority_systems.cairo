use starknet::{ContractAddress};

// Define the interface for the Dust system
#[dojo::interface]
trait IAuthoritySystems {
    fn transfer_ownership(ref world: IWorldDispatcher, body_id: u32, new_owner: ContractAddress);
}

// Dojo decorator
#[dojo::contract]
mod authority_systems {
    use super::{IAuthoritySystems};
    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::owner::Owner;

    // Structure to represent a DustPoolFormed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct OwnershipTransferred {
        #[key]
        body_id: u32,
        new_owner: ContractAddress,
    }

    #[abi(embed_v0)]
    impl AuthoritySystemsImpl of IAuthoritySystems<ContractState> {
        fn transfer_ownership(
            ref world: IWorldDispatcher, body_id: u32, new_owner: ContractAddress
        ) {
            let caller = get_caller_address();
            let ownership = get!(world, body_id, (Owner));

            assert(caller == ownership.address, 'not owner');

            InternalAuthoritySystemsImpl::transfer_ownership(world, body_id, new_owner);
        }
    }

    #[generate_trait]
    impl InternalAuthoritySystemsImpl of InternalAuthoritySystemsTrait {
        fn transfer_ownership(world: IWorldDispatcher, body_id: u32, new_owner: ContractAddress) {
            set!(world, (Owner { entity: body_id, address: new_owner }));
        }
    }
}
