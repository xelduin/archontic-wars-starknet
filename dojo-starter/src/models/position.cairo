use dojo_starter::models::vec2::Vec2;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Position {
    #[key]
    pub entity: u32,
    pub vec: Vec2,
}
