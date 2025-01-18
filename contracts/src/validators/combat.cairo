use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};
use dojo::event::EventStorage;

use astraplani::utils::combat::get_attack_range;

use astraplani::models::vec2::{Vec2, Vec2Impl};

fn assert_is_in_attack_range(mut world: WorldStorage, attacker_id: u32, target_id: u32) {
    let attack_range = get_attack_range(world, attacker_id);

    let attacker_coords: Position = world.read_model(attacker_id);
    let defender_coords: Position = world.read_model(target_id);

    let distance = attacker_coords.vec.distance_to(defender_coords.vec);

    assert(attack_range >= distance, 'not in attack range');
}

fn assert_is_not_in_combat(mut world: WorldStorage, entity_id: u32) {
    let combat_action = get_combat_action(world, entity_id);

    match combat_action {
        Option::Some(_) => panic!('entity in combat'),
        Option::None => ()
    }
}

