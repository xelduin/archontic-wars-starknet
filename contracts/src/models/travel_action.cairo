use astraplani::models::vec2::Vec2;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TravelAction {
    #[key]
    pub entity_id: u32,
    pub depart_ts: u64,
    pub arrival_ts: u64,
    pub target_position: Vec2,
}
