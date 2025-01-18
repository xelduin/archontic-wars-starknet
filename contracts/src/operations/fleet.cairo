use dojo::world::WorldStorage;
use dojo::model::{ModelStorage, ModelValueStorage};

use astraplani::models::fleet_formation::{FleetComposition, FleetFormation, FleetFormationImpl};

fn set_fleet_to_star_inventory(world: WorldStorage, star_id: u32, new_fleet: FleetComposition) {
    let mut star_inventory: FleetFormation = world.read_model(star_id);

    let updated_star_inventory = star_inventory.add(new_fleet);

    world.write_model(star_id, updated_star_inventory);
}

fn deduct_fleet(world: WorldStorage, fleet_id: u32, fleet_deduction: FleetComposition) {
    let fleet_formation: FleetFormation = world.read_model(fleet_id);

    assert(
        fleet_formation.fleet.scouts >= fleet_deduction.scouts
            && fleet_formation.fleet.harvesters >= fleet_deduction.harvesters
            && fleet_formation.fleet.carriers >= fleet_deduction.carriers
            && fleet_formation.fleet.dreadnoughts >= fleet_deduction.dreadnoughts,
        'fleet deduction exceeds fleet size'
    );

    let updated_fleet = FleetFormation {
        entity_id: fleet_id,
        composition: FleetComposition {
            scouts: fleet_formation.fleet.scouts - fleet_deduction.scouts,
            harvesters: fleet_formation.fleet.harvesters - fleet_deduction.harvesters,
            carriers: fleet_formation.fleet.carriers - fleet_deduction.carriers,
            dreadnoughts: fleet_formation.fleet.dreadnoughts - fleet_deduction.dreadnoughts,
        }
    };

    world.write_model(updated_fleet);
}
