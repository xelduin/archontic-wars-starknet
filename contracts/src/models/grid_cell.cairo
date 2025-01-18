use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};


#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct GridCell {
    #[key]
    pub x: u64,
    #[key]
    pub y: u64,
    pub entity_id: u32,
}
