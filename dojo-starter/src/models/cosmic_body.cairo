#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct CosmicBody {
    #[key]
    pub entity: u32,
    pub body_type: CosmicBodyType,
}

#[derive(Serde, Copy, Drop, PartialEq, Introspect)]
pub enum CosmicBodyType {
    None,
    Galaxy,
    Protostar,
    Star,
    AsteroidCluster,
}
