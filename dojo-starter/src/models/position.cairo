use dojo_starter::models::vec2::{Vec2, Vec2Impl};
use dojo_starter::models::orbit::Orbit;
use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};


#[derive(Copy, Drop, Serde, Introspect)]
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
