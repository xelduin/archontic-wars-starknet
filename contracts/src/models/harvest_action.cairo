#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct HarvestAction {
    #[key]
    pub entity_id: u32,
    pub start_ts: u64,
    pub end_ts: u64,
    pub harvest_amount: u128,
}
