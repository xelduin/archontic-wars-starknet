use starknet::ContractAddress;
use dojo_starter::models::vec2::Vec2;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct TravelAction {
    #[key]
    pub entity: ContractAddress,
    pub depart_ts: u64,
    pub arrival_ts: u64,
    pub target_position: Vec2,
}
