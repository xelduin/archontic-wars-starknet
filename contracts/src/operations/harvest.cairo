use starknet::{get_block_timestamp};

use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::validators::dust::assert_can_carry_dust;
use astraplani::validators::dust::assert_has_dust_balance;
use astraplani::validators::harvest::assert_harvest_ended;
use astraplani::validators::harvest::assert_harvest_not_ended;

use astraplani::utils::harvest::get_harvest_time;
use astraplani::utils::harvest::get_harvest_amount_interpolation;
use astraplani::utils::harvest::calculate_partial_harvest_amount;
use astraplani::utils::harvest::get_actual_dust_amount;


use astraplani::models::action_status::{ActionStatus};
use astarplani::models::harvest_action::{HarvestAction, HarvestParams};

fn initialize(world: WorldStorage, asteroid_id: u32, params: HarvestParams) {
    let harvest_time = get_harvest_time(asteroid_id, params.amount);
    let start_ts = get_block_timestamp();
    let end_ts = start_ts + harvest_time;

    let new_harvest_action = HarvestAction { entity_id: asteroid_id, start_ts, end_ts, params };

    world.write_model(@new_harvest_action);
}

fn complete(world: WorldStorage, asteroid_id: u32) {
    assert_harvest_ended(world, asteroid_id);

    let harvest_action = get_harvest_action(world, asteroid_id);
    let actual_dust_amount = get_actual_harvest_amount(world, asteroid_id);

    operations::dust::transfer_dust(
        world, asteroid_id, harvest_aciton.params.dust_cloud_id, actual_dust_amount
    );

    world.erase_model(@harvest_action);
}

fn interrupt(world: WorldStorage, asteroid_id: u32) {
    assert_harvest_not_ended(world, asteroid_id);

    complete(world, asteroid_id);
}
