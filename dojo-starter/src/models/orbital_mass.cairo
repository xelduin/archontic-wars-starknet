#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct OrbitalMass {
    #[key]
    pub entity: u32,
    pub orbital_mass: u64,
}
