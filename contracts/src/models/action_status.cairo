use starknet::ContractAddress;
use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::harvest_action::HarvestParams;
use astraplani::models::travel_action::TravelParams;
use astraplani::models::battle_action::BattleParams;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct ActionStatus {
    #[key]
    pub entity_id: u32,
    pub action_type: ActionType,
}

#[derive(Serde, Copy, Drop, PartialEq, Introspect)]
enum ActionType {
    Idle,
    Harvest,
    Travel,
    Battle
}

#[derive(Serde, Copy, Drop, PartialEq, Introspect)]
enum ActionParams {
    Harvest: HarvestParams,
    Travel: TravelParams,
    Battle: BattleParams,
}

