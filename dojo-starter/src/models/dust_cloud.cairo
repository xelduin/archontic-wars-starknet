#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustCloud {
    #[key]
    pub x: u64,
    #[key]
    pub y: u64,
    #[key]
    pub orbit_center: u32,
    pub dust_balance: u128,
}
