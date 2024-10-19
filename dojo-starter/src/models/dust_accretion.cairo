#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustAccretion {
    #[key]
    pub entity: u32,
    pub debt: u128,
    pub in_dust_pool: bool
}
