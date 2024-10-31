#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Orbit {
    #[key]
    pub entity: u32,
    pub orbit_center: u32,
}
