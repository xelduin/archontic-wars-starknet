use starknet::{ContractAddress};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::models::owner::Owner;

fn assert_is_owner(mut world: WorldStorage, entity_id: u32, address: ContractAddress) {
    let entity_owner: Owner = world.read_model(entity_id);

    assert(entity_owner == address, 'not owner');
}
