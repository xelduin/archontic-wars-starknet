#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct Battle {
    #[key]
    pub battle_id: u32,
    pub primary_attacker: u32,
    pub primary_defender: u32,
    pub attacker_reinforcements: Array<u32, 7>,
    pub defender_reinforcements: Array<u32, 7>,
    pub attacker_power: BattleSidePower,
    pub defender_power: BattleSidePower,
    pub start_ts: u64,
    pub end_ts: u64,
}
