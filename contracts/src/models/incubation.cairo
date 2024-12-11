use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Incubation {
    #[key]
    pub entity_id: u32,
    pub creation_ts: u64,
    pub end_ts: u64,
}
