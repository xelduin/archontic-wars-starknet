use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IStarManagementSystem<T> {
    fn create_star(ref self: T, anima_token_id: u32, coords: Vec2);
    fn claim_star_pneuma(ref self: T, star_id: u32);
    fn claim_star_dust(ref self: T, star_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod star_management_systems {
    use super::{IStarManagementSystem};
    use starknet::{ContractAddress, get_caller_address};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::WorldStorage;

    use astraplani::models::owner::Owner;
    use astraplani::models::Vec2;
    use astraplani::models::GridCell;
    use astraplani::models::DustBalance;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct StarCreated {
        #[key]
        entity_id: u32,
        anima_id: u32,
        coords: Vec2,
    }

    #[abi(embed_v0)]
    impl StarManagementSystemsImpl of IStarManagementSystem<ContractState> {
        fn create_star(ref self: ContractState, anima_token_id: u32, coords: Vec2) {
            let mut world = self.world(@"ns");
            assert_is_owner(world, anima_token_id);
            //can_create_star_at_coord(coords)
        //generate_star_data(anima_id)
        //write_star_data
        //emit_event
        }

        fn claim_star_pneuma(ref self: ContractState, star_id: u32) {
            let mut world = self.world(@"ns");
            assert_is_owner(world, star_id);
            //get_unclaimed_pneuma
        //mint_pneuma
        //emit_event
        }

        fn claim_star_dust(ref self: ContractState, star_id: u32) {
            let mut world = self.world(@"ns");
            assert_is_owner(world, star_id);
            //get_unclaimed_dust
        //update_star_dust_
        //emit_event
        }
    }
}
