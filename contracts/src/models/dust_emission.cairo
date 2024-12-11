#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustEmission {
    #[key]
    pub entity_id: u32,
    pub emission_rate: u128,
    pub ARPS: u128,
    pub last_update_ts: u64,
}
