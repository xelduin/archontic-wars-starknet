#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustBalance {
    #[key]
    pub entity_id: u32,
    pub balance: u128,
}
