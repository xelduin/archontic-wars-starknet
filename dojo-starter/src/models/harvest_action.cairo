#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct HarvestAction {
    #[key]
    pub entity: u32,
    pub start_ts: u64,
    pub end_ts: u64,
    pub harvest_amount: u64,
}
