#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct OrbitalMass {
    #[key]
    pub entity_id: u32,
    pub orbital_mass: u64,
}
