#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DustPool {
    #[key]
    pub entity: u32,
    pub total_mass: u64,
}
