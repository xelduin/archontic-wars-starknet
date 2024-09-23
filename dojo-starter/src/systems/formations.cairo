use dojo_starter::models::position::Position;

// define the interface
#[dojo::interface]
trait IFormations {
    fn spawn(ref world: IWorldDispatcher);
}

// dojo decorator
#[dojo::contract]
mod formations {
    use super::{IFormations};
    use starknet::{ContractAddress, get_caller_address};
    use dojo_starter::models::{vec2::Vec2, position::Position};

    #[abi(embed_v0)]
    impl FormationsImpl of IFormations<ContractState> {
        fn spawn(ref world: IWorldDispatcher) {
            // Get the address of the current caller, possibly the player's address.
            let player = get_caller_address();
            // Retrieve the player's current position from the world.
            // Update the world state with the new data.
            // 1. Set the player's remaining moves to 100.
            // 2. Move the player's position 10 units in both the x and y direction.

            set!(world, (Position { entity: player, vec: Vec2 { x: 27, y: 30 } },));
        }
    }
}
