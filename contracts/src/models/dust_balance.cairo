#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustBalance {
    #[key]
    pub entity: u32,
    pub balance: u128,
}
