#[derive(Serde, Copy, Drop, PartialEq, Introspect)]
pub enum AsteroidClass {
    Scout,
    Harvester,
    Carrier,
    Dreadnought,
    AsteroidCluster,
}
