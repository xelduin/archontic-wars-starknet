use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait ICombatSystem<T> {
    fn start_combat(ref self: T, attacker_id: u32, target_id: u32);
    fn end_combat(ref self: T, attacker_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod combat_systems {
    use super::{ICombatSystem};
    use starknet::{ContractAddress, get_caller_address};

    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;
    use dojo::world::WorldStorage;

    use astraplani::validators::ownership::assert_is_owner;
    use astraplani::validators::action_status::assert_is_idle;
    use astraplani::validators::combat::assert_is_in_attack_range;
    use astraplani::validators::combat::assert_is_not_in_combat;
    use astraplani::validators::battle::assert_can_end_battle;

    use astraplani::utils::battle::get_pneuma_attack_cost;
    use astraplani::utils::battle::get_battle;

    use astraplani::models::owner::Owner;
    use astraplani::models::Vec2;
    use astraplani::models::combat_action::{CombatAction, CombatParams, CombatRole, Force};

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct CombatStarted {
        #[key]
        attacker_id: u32,
        target_id: u32,
        coords: Vec2,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    pub struct CombatEnded {
        #[key]
        attacker_id: u32,
        target_id: u32,
        coords: Vec2,
    }

    #[abi(embed_v0)]
    impl AsteroidBattleSystemsImpl of ICombatSystem<ContractState> {
        fn start_combat(ref self: ContractState, attacker_id: u32, target_id: u32) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, attacker_id, get_caller_address());
            assert_is_idle(world, attacker_id);
            assert_is_in_attack_range(world, attacker_id, target_id);
            assert_is_not_in_combat(world, target_id);

            let pneuma_cost = get_pneuma_attack_cost(world, attacker_id, target_id);
            assert_has_pneuma_balance(world, get_caller_address());

            let battle_id = operations::battle::initialize(world, attacker_id, target_id);

            let attacker_params = CombatParams {
                battle_id, role: CombatRole::Attacker, force: Force::Primary
            };
            let defender_params = CombatParams {
                battle_id, role: CombatRole::Defender, force: Force::Primary
            };

            operators::action::cancel_action(world, target_id);

            operators::action::start_action(
                world, attacker_id, ActionParams::Combat(attacker_params)
            );
            operators::action::start_action(
                world, target_id, ActionParams::Combat(defender_params)
            );
        }

        fn end_combat(ref self: ContractState, asteroid_id: u32) {
            let mut world = self.world(@"ns");

            assert_is_owner(world, asteroid_id, get_caller_address());
            assert_can_end_battle(world, asteroid_id);

            let battle = get_battle(world, asteroid_id);

            operators::action::end_action(world, battle.attacker_id);
            operators::action::end_action(world, battle.defender_id);
        }
    }
}
