#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BasalAttributes {
    #[key]
    pub entity: u32,
    pub attributes: u8, // Assuming 12 attributes as stated
}
