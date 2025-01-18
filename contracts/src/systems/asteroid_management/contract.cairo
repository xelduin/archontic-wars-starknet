use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IAsteroidManagementSystems<T> {
    fn create_asteroid(ref self: T, star_id: u32, mass: u128);
}

// Dojo decorator
#[dojo::contract]
mod asteroid_management_systems {
    use super::{IAsteroidManagementSystems};
    use starknet::{ContractAddress, get_caller_address};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::WorldStorage;

    use astraplani::models::owner::Owner;
    use astraplani::models::Vec2;
    use astraplani::models::GridCell;
    use astraplani::models::DustBalance;

    use astraplani::validators::owner::assert_is_owner;
    use astraplani::validators::dust::assert_has_dust_balance;
    use astraplani::utils::creation::get_asteroid_creation_dust_cost;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct AsteroidCreated {
        #[key]
        entity_id: u32,
        star_id: u32,
        mass: u128,
    }

    #[abi(embed_v0)]
    impl AsteroidManagementSystemsImpl of IAsteroidManagementSystems<ContractState> {
        fn create_asteroids(ref self: ContractState, star_id: u32, fleet: FleetComposition) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, star_id, get_caller_address());
            let dust_cost = get_fleet_creation_dust_cost(star_id, fleet);
            assert_has_dust_balance(star_id, dust_cost);

            write_asteroids_to_star_inventory(world, star_id, fleet);
            //emit_event
        }
    }
}
