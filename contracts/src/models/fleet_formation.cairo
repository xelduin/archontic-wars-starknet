use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Store)]
struct FleetComposition {
    scout_count: u32,
    harvester_count: u32,
    carrier_count: u32,
    dreadnought_count: u32,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
struct FleetFormation {
    entity_id: u32,
    composition: FleetComposition,
}

trait FleetCompositionImpl {
    fn add(self: FleetComposition, other: FleetComposition) -> FleetComposition;
    fn subtract(self: FleetComposition, other: FleetComposition) -> FleetComposition;
    fn is_valid(self: FleetComposition) -> bool;
    fn total_units(self: FleetComposition) -> u32;
}

impl FleetCompositionImpl of FleetCompositionImpl {
    fn add(self: FleetComposition, other: FleetComposition) -> FleetComposition {
        FleetComposition {
            scout_count: self.scout_count + other.scout_count,
            harvester_count: self.harvester_count + other.harvester_count,
            carrier_count: self.carrier_count + other.carrier_count,
            dreadnought_count: self.dreadnought_count + other.dreadnought_count,
        }
    }

    fn subtract(self: FleetComposition, other: FleetComposition) -> FleetComposition {
        FleetComposition {
            scout_count: self.scout_count - other.scout_count,
            harvester_count: self.harvester_count - other.harvester_count,
            carrier_count: self.carrier_count - other.carrier_count,
            dreadnought_count: self.dreadnought_count - other.dreadnought_count,
        }
    }

    fn total_units(self: FleetComposition) -> u32 {
        self.scout_count + self.harvester_count + self.carrier_count + self.dreadnought_count
    }
}
