#[derive(Serde, Copy, Drop, Introspect)]
pub enum LooshSink {
    CreateQuasar,
    CreateProtostar,
    FormStar,
    CreateAsteroidCluster,
}
