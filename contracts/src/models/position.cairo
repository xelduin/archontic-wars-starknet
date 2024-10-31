use astraplani::models::vec2::{Vec2, Vec2Impl};
use astraplani::models::orbit::Orbit;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct OrbitCenterAtPosition {
    #[key]
    pub x: u64,
    #[key]
    pub y: u64,
    #[key]
    pub orbit_center: u32,
    pub entity: u32,
}


#[derive(Copy, Drop, Serde,)]
#[dojo::model]
pub struct Position {
    #[key]
    pub entity: u32,
    pub vec: Vec2,
}

#[generate_trait]
impl PositionCustomImpl of PositionCustomTrait {
    fn is_equal(self: Position, world: IWorldDispatcher, target: Position) -> bool {
        let self_orbit = get!(world, self.entity, Orbit);
        let target_orbit = get!(world, target.entity, Orbit);

        return self_orbit.orbit_center == target_orbit.orbit_center
            && self.vec.is_equal(target.vec);
    }
}
