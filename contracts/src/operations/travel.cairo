use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::operators;

use astraplani::utils::travel::get_travel_duration;

use astraplani::validators::travel::assert_travel_ended;
use astraplani::validators::travel::assert_travel_not_ended;

use astraplani::models::vec2::Vec2;
use astraplani::models::position::Position;
use astraplani::models::travel_action::{TravelAction, TravelParams};

fn initialize(world: WorldStorage, asteroid_id: u32, params: TravelParams) {
    let start_ts = get_block_timestamp();
    let end_ts = start_ts + get_travel_duration(world, asteroid_id, travel_params);

    let new_travel_action = TravelAction { entity_id: asteroid_id, params };

    world.write_model(@new_harvest_action);
}

fn complete(world: WorldStorage, asteroid_id: u32) {
    assert_travel_ended(world, asteroid_id);

    let travel_action = get_travel_action(world, asteroid_id);

    operations::map::set_position(world, asteroid_id, travel_action.params.end_position);

    world.erase_model(@travel_action);
}

fn interrupt(world: WorldStorage, asteroid_id: u32) {
    assert_travel_not_ended(world, asteroid_id);

    let travel_action = get_travel_action(world, asteroid_id);
    let partial_travel_position = get_ongoing_travel_position(travel_action);

    operations::map::set_position(world, asteroid_id, partial_travel_position);

    world.erase_model(@travel_action);
}
