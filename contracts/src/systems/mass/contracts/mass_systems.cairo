use starknet::{ContractAddress};

// Define the interface for the Dust system
#[starknet::interface]
trait IMassSystems<T> {
    fn transfer_mass(ref self: T, sender_body_id: u32, receiver_body_id: u32, mass: u64);
}

// Dojo decorator
#[dojo::contract]
mod mass_systems {
    use dojo::world::WorldStorage;
    use dojo::model::{ModelStorage, ModelValueStorage};
    use dojo::event::EventStorage;

    use super::{IMassSystems};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};

    use astraplani::systems::dust::contracts::dust_systems::dust_systems::InternalDustSystemsImpl;

    use astraplani::models::mass::Mass;
    use astraplani::models::owner::Owner;
    use astraplani::models::cosmic_body::{CosmicBody, CosmicBodyType};
    use astraplani::models::position::{Position, PositionCustomImpl};
    use astraplani::models::dust_accretion::DustAccretion;
    use astraplani::models::orbital_mass::OrbitalMass;
    use astraplani::models::orbit::Orbit;

    #[derive(Copy, Drop, Serde)]
    #[dojo::event]
    struct BodyMassChange {
        #[key]
        body_id: u32,
        old_mass: u64,
        new_mass: u64
    }

    #[abi(embed_v0)]
    impl MassSystemsImpl of IMassSystems<ContractState> {
        fn transfer_mass(
            ref self: ContractState, sender_body_id: u32, receiver_body_id: u32, mass: u64
        ) {
            let mut world = self.world(@"ns");

            let caller = get_caller_address();
            let ownership: Owner = world.read_model(sender_body_id);
            assert(caller == ownership.address, 'not owner');

            InternalMassSystemsImpl::transfer_mass(world, sender_body_id, receiver_body_id, mass);
        }
    }

    #[generate_trait]
    impl InternalMassSystemsImpl of InternalMassSystemsTrait {
        fn transfer_mass(
            mut world: WorldStorage, sender_body_id: u32, receiver_body_id: u32, mass: u64
        ) {
            let sender_type: CosmicBody = world.read_model(sender_body_id);
            assert(
                sender_type.body_type == CosmicBodyType::AsteroidCluster, 'not asteroid cluster'
            );

            let sender_position: Position = world.read_model(sender_body_id);
            let receiver_position: Position = world.read_model(receiver_body_id);
            assert(sender_position.is_equal(world, receiver_position), 'not in proximity');

            Self::decrease_mass(world, sender_body_id, mass);
            Self::increase_mass(world, receiver_body_id, mass);
        }

        fn increase_mass(mut world: WorldStorage, body_id: u32, mass: u64) {
            let body_mass: Mass = world.read_model(body_id);
            let new_mass = mass + body_mass.mass;

            let body_orbit: Orbit = world.read_model(body_id);
            let parent_orbital_mass: OrbitalMass = world.read_model(body_orbit.orbit_center);

            let new_mass_model = Mass { entity: body_id, mass: new_mass };
            let new_orbital_mass_model = OrbitalMass {
                            entity: body_orbit.orbit_center,
                            orbital_mass: parent_orbital_mass.orbital_mass + mass
            };

            world.write_model(@new_mass_model);
            world.write_model(@new_orbital_mass_model);
            
            Self::on_body_mass_change(world, body_id, body_mass.mass, new_mass);
        }

        fn decrease_mass(mut world: WorldStorage, body_id: u32, mass: u64) {
            let body_mass: Mass = world.read_model(body_id);
            assert(body_mass.mass > mass, 'not enough mass');
            let new_mass = body_mass.mass - mass;

            let body_orbit: Orbit = world.read_model(body_id);
            let parent_orbital_mass: OrbitalMass = world.read_model(body_orbit.orbit_center);

            let new_mass_model = Mass { entity: body_id, mass: new_mass };
            let new_orbital_mass_model = OrbitalMass {
                entity: body_orbit.orbit_center,
                orbital_mass: parent_orbital_mass.orbital_mass - mass
            };

            world.write_model(@new_mass_model);
            world.write_model(@new_orbital_mass_model);

            Self::on_body_mass_change(world, body_id, body_mass.mass, new_mass);
        }

        fn on_body_mass_change(
            mut world: WorldStorage, body_id: u32, old_mass: u64, new_mass: u64
        ) {
            world.emit_event(@(BodyMassChange { body_id, old_mass, new_mass }));

            let body_accretion: DustAccretion = world.read_model(body_id);
            if body_accretion.in_dust_pool {
                InternalDustSystemsImpl::update_pool_member(world, body_id, old_mass, new_mass);
            }
        }
    }
}
