#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct CombatAction {
    #[key]
    pub entity_id: u32,
    pub params: CombatParams,
}

#[derive(Copy, Drop, Serde)]
pub struct CombatParams {
    pub battle_id: u32,
    pub amount: u128,
    pub role: CombatRole,
    pub force: Force
}

#[derive(Copy, Drop, Serde)]
pub enum CombatRole {
    Attacker,
    Defender
}

#[derive(Copy, Drop, Serde)]
pub enum CombatParams {
    Primary,
    Reinforcement
}

