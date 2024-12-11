use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::orbit::Orbit;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};


#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct OrbitCenterAtPosition {
    #[key]
    pub x: u64,
    #[key]
    pub y: u64,
    #[key]
    pub orbit_center: u32,
    pub entity_id: u32,
}


#[derive(Copy, Drop, Serde,)]
#[dojo::model]
pub struct Position {
    #[key]
    pub entity_id: u32,
    pub vec: Vec2,
}

#[generate_trait]
impl PositionCustomImpl of PositionCustomTrait {
    fn is_equal(self: Position, mut world: WorldStorage, target: Position) -> bool {
        let self_orbit: Orbit = world.read_model(self.entity_id);
        let target_orbit: Orbit = world.read_model(target.entity_id);

        return self_orbit.orbit_center == target_orbit.orbit_center
            && self.vec.is_equal(target.vec);
    }
}
