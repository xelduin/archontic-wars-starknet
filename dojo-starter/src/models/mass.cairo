#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Mass {
    #[key]
    pub entity: u32,
    pub mass: u64,
}
