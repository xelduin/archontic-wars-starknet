#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct HarvestAction {
    #[key]
    pub entity_id: u32,
    pub start_ts: u64,
    pub end_ts: u64,
    pub params: HarvestParams,
}

#[derive(Copy, Drop, Serde)]
pub struct HarvestParams {
    pub dust_cloud_id: u32,
    pub amount: u128,
}
