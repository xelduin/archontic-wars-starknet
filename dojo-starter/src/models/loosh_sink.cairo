#[derive(Serde, Copy, Drop, Introspect)]
pub enum LooshSink {
    CreateGalaxy,
    CreateProtostar,
    FormStar,
    CreateAsteroidCluster,
}
