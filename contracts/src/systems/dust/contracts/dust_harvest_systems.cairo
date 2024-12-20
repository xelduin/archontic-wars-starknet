#[starknet::interface]
trait IDustHarvestSystems<T> {
    fn begin_dust_harvest(ref self: T, body_id: u32, harvest_amount: u128);
    fn end_dust_harvest(ref self: T, body_id: u32);
    fn cancel_dust_harvest(ref self: T, body_id: u32);
}

#[dojo::contract]
mod dust_harvest_systems {
    use super::{IDustHarvestSystems};

    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestActionBegan {
        #[key]
        body_id: u32,
        cloud_coords: Vec2,
        amount: u128,
        harvest_end_ts: u64
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestActionEnded {
        #[key]
        body_id: u32,
        cloud_coords: Vec2,
        amount: u128,
    }

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct HarvestActionCancelled {
        #[key]
        body_id: u32,
        cloud_coords: Vec2,
    }

    #[abi(embed_v0)]
    impl DustHarvestSystems of IDustHarvestSystems<ContractState> {
        fn begin_dust_harvest(ref self: ContractState, body_id: u32, harvest_amount: u128) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::begin_dust_harvest(world, body_id, harvest_amount);
        }
        fn end_dust_harvest(ref self: ContractState, body_id: u32) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::end_dust_harvest(world, body_id);
        }
        fn cancel_dust_harvest(ref self: ContractState, body_id: u32) {
            let mut world = self.world(@"ns");
            InternalDustSystemsImpl::cancel_dust_harvest(world, body_id);
        }
    }

    #[generate_trait]
    impl InternalDustHarvestSystemsImpl of InternalDustHarvestSystemsTrait {
        fn begin_dust_harvest(mut world: WorldStorage, body_id: u32, harvest_amount: u128) {
            let caller = get_caller_address();
            let owner: Owner = world.read_model(body_id);
            assert(caller == owner.address, 'not owner');

            let body_type: CosmicBody = world.read_model(body_id);
            assert(body_type.body_type == CosmicBodyType::AsteroidCluster, 'invalid body type');

            let body_position: Position = world.read_model(body_id);
            let body_orbit: Orbit = world.read_model(body_id);
            let dust_cloud: DustCloud = world
                .read_model((body_position.vec.x, body_position.vec.y, body_orbit.orbit_center));
            assert(dust_cloud.dust_balance >= harvest_amount, 'not enough dust');

            let body_mass: Mass = world.read_model(body_id);
            let dust_value_config: DustValueConfig = world.read_model(DUST_VALUE_CONFIG_ID);
            let mass_to_dust = dust_value_config.mass_to_dust;
            let harvest_capacity: u128 = body_mass.mass.try_into().unwrap() * mass_to_dust;
            assert(harvest_capacity >= harvest_amount, 'harvest amount too high');

            // CHECK FOR ACTIONS
            let harvest_action: HarvestAction = world.read_model(body_id);
            assert(harvest_action.end_ts == 0, 'entity already harvesting');
            let travel_action: TravelAction = world.read_model(body_id);
            assert(travel_action.arrival_ts == 0, 'cannot harvest while travelling');

            let cur_ts = get_block_timestamp();
            let end_ts = get_harvest_end_ts(world, cur_ts, harvest_amount, body_mass.mass);

            let new_harvest_action = HarvestAction {
                entity_id: body_id, start_ts: cur_ts, end_ts, harvest_amount
            };

            world.write_model(@new_harvest_action);

            world
                .emit_event(
                    @(HarvestActionBegan {
                        body_id,
                        cloud_coords: body_position.vec,
                        amount: harvest_amount,
                        harvest_end_ts: end_ts
                    })
                );
        }

        fn end_dust_harvest(mut world: WorldStorage, body_id: u32) {
            let caller = get_caller_address();
            let owner: Owner = world.read_model(body_id);
            assert(caller == owner.address, 'not owner');

            let body_position: Position = world.read_model(body_id);
            let body_orbit: Orbit = world.read_model(body_id);
            let dust_cloud: DustCloud = world
                .read_model((body_position.vec.x, body_position.vec.y, body_orbit.orbit_center));

            let cur_ts = get_block_timestamp();
            let harvest_action: HarvestAction = world.read_model(body_id);
            assert(harvest_action.end_ts != 0, 'not harvesting');
            assert(cur_ts >= harvest_action.end_ts, 'harvest still underway');

            world.erase_model(@(harvest_action));

            let body_dust_balance: DustBalance = world.read_model(body_id);
            let harvested_dust = if harvest_action.harvest_amount > dust_cloud.dust_balance {
                dust_cloud.dust_balance
            } else {
                harvest_action.harvest_amount
            };

            let new_dust_balance = DustBalance {
                entity_id: body_id, balance: body_dust_balance.balance + harvested_dust
            };
            let new_dust_cloud = DustCloud {
                x: body_position.vec.x,
                y: body_position.vec.y,
                orbit_center: body_orbit.orbit_center,
                dust_balance: dust_cloud.dust_balance - harvested_dust
            };

            world.write_model(@new_dust_balance);
            world.write_model(@new_dust_cloud);

            let harvest_action_ended_event = HarvestActionEnded {
                body_id, amount: harvested_dust, cloud_coords: body_position.vec
            };
            let dust_cloud_change_event = DustCloudChange {
                coords: body_position.vec,
                old_dust_amount: dust_cloud.dust_balance,
                new_dust_amount: dust_cloud.dust_balance + harvested_dust
            };

            world.emit_event(@harvest_action_ended_event);
            world.emit_event(@dust_cloud_change_event);
        }

        fn cancel_dust_harvest(mut world: WorldStorage, body_id: u32) {
            let caller = get_caller_address();
            let owner: Owner = world.read_model(body_id);
            assert(caller == owner.address, 'not owner');

            let harvest_action: HarvestAction = world.read_model(body_id);
            assert(harvest_action.end_ts != 0, 'not harvesting');

            let body_position: Position = world.read_model(body_id);

            world.erase_model(@harvest_action);
            world
                .emit_event(@(HarvestActionCancelled { body_id, cloud_coords: body_position.vec }));
        }
    }
}
