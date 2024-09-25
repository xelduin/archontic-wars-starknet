#[derive(Serde, Copy, Drop, Introspect)]
pub enum LooshSink {
    CreateProtostar,
    FormStar,
    CreateAsteroidCluster,
}
