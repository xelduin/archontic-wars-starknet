use starknet::{ContractAddress};

// Define the interface for the Dust system
#[dojo::interface]
trait IMassSystems {
    fn transfer_mass(
        ref world: IWorldDispatcher, sender_body_id: u32, receiver_body_id: u32, mass: u64
    );
}

// Dojo decorator
#[dojo::contract]
mod mass_systems {
    use super::{IMassSystems};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use dojo_starter::models::mass::Mass;
    use dojo_starter::models::owner::Owner;
    use dojo_starter::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use dojo_starter::models::vec2::Vec2;
    use dojo_starter::models::position::{Position, PositionCustomImpl};
    use dojo_starter::models::dust_accretion::DustAccretion;
    use dojo_starter::systems::dust::contracts::dust_systems::dust_systems::{
        InternalDustSystemsImpl
    };

    #[abi(embed_v0)]
    impl MassSystemsImpl of IMassSystems<ContractState> {
        fn transfer_mass(
            ref world: IWorldDispatcher, sender_body_id: u32, receiver_body_id: u32, mass: u64
        ) {
            let caller = get_caller_address();
            let ownership = get!(world, sender_body_id, (Owner));
            assert(caller == ownership.address, 'not owner');

            InternalMassSystemsImpl::transfer_mass(world, sender_body_id, receiver_body_id, mass);
        }
    }

    #[generate_trait]
    impl InternalMassSystemsImpl of InternalMassSystemsTrait {
        fn transfer_mass(
            world: IWorldDispatcher, sender_body_id: u32, receiver_body_id: u32, mass: u64
        ) {
            let sender_type = get!(world, sender_body_id, (CosmicBody));
            assert(
                sender_type.body_type == CosmicBodyType::AsteroidCluster, 'not asteroid cluster'
            );

            let sender_position = get!(world, sender_body_id, (Position));
            let receiver_position = get!(world, receiver_body_id, (Position));
            assert(sender_position.is_equal(world, receiver_position), 'not in proximity');

            Self::decrease_mass(world, sender_body_id, mass);
            Self::increase_mass(world, receiver_body_id, mass);
        }

        fn increase_mass(world: IWorldDispatcher, body_id: u32, mass: u64) {
            let body_mass = get!(world, body_id, (Mass));
            let new_mass = mass + body_mass.mass;

            Self::on_body_mass_change(world, body_id, body_mass.mass, new_mass);
        }

        fn decrease_mass(world: IWorldDispatcher, body_id: u32, mass: u64) {
            let body_mass = get!(world, body_id, (Mass));
            assert(body_mass.mass > mass, 'not enough mass');
            let new_mass = body_mass.mass - mass;

            Self::on_body_mass_change(world, body_id, body_mass.mass, new_mass);
        }

        fn on_body_mass_change(
            world: IWorldDispatcher, body_id: u32, old_mass: u64, new_mass: u64
        ) {
            set!(world, (Mass { entity: body_id, mass: new_mass }));

            let body_accretion = get!(world, body_id, DustAccretion);
            if body_accretion.in_dust_pool {
                InternalDustSystemsImpl::update_pool_member(world, body_id, old_mass, new_mass);
            }
        }
    }
}
