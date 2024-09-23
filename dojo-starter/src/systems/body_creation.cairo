use starknet::{ContractAddress, get_caller_address};

// Define the interface for the Body creation system
#[dojo::interface]
trait IBodyCreation {
    fn spawn_protostar(ref world: IWorldDispatcher, archetype_id: u32, x: u64, y: u64);
    fn form_star(ref world: IWorldDispatcher, protostar_id: u32);
    fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32);
    fn define_new_asteroid_cluster(ref world: IWorldDispatcher, star_id: u32);
}

// Dojo decorator
#[dojo::contract]
mod body_creation {
    use super::IBodyCreation;
    use starknet::{ContractAddress, get_caller_address};

    // Structure to represent a ProtostarSpawned event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct ProtostarSpawned {
        #[key]
        archetype_id: u32,
        x: u64,
        y: u64,
    }

    // Structure to represent a StarFormed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct StarFormed {
        #[key]
        protostar_id: u32,
        timestamp: u64,
    }

    // Structure to represent AsteroidsFormed event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct AsteroidsFormed {
        #[key]
        star_id: u32,
        cluster_id: u32,
    }

    // Structure to represent AsteroidClusterDefined event
    #[derive(Copy, Drop, Serde)]
    #[dojo::model]
    #[dojo::event]
    struct AsteroidClusterDefined {
        #[key]
        star_id: u32,
        cluster_id: u32,
    }

    #[abi(embed_v0)]
    impl BodyCreationImpl of IBodyCreation<ContractState> {
        fn spawn_protostar(ref world: IWorldDispatcher, archetype_id: u32, x: u64, y: u64) {
            // Retrieve the current caller's address
            //let player = get_caller_address();

            // 1. Check if player has enough Loosh to reference the archetype.
            // 2. Call reference_archetype(archetype_id).
            // 3. Initialize the Protostar entity with BasalAttributes.
            // 4. Set components: Incubation, Owner, Mass, Position.
            // 5. Determine if it should orbit something, then call enter_orbit.
            // 6. Add the Protostar to the DustPool.

            // Emit an event to signal Protostar creation
            emit!(world, (ProtostarSpawned { archetype_id, x, y }));
        }

        fn form_star(ref world: IWorldDispatcher, protostar_id: u32) {
            // 1. Check ownership: ensure the caller is the owner of the protostar.
            // 2. Check if the incubation period is over.
            // 3. Convert the protostar's entity type to Star.
            // 4. Update relevant attributes (e.g., increase Mass, change BodyType to Star).

            // Emit an event for the newly formed star
            emit!(world, (StarFormed { protostar_id, timestamp: 0 }));
        }

        fn form_asteroids(ref world: IWorldDispatcher, star_id: u32, cluster_id: u32) {
            // 1. Verify that the body is a Star.
            // 2. Loop over the star's DustPool and distribute mass to the asteroid cluster.
            // 3. If no cluster_id is provided, call define_new_asteroid_cluster.
            // 4. Call consume_dust for dust processing.
            // 5. Update Mass for the star after forming asteroids.

            // Emit an event for asteroid formation
            emit!(world, (AsteroidsFormed { star_id, cluster_id }));
        }

        fn define_new_asteroid_cluster(ref world: IWorldDispatcher, star_id: u32) {
            // 1. Initialize a new body as an AsteroidCluster.
            // 2. Set the position of the new cluster to match the star's current position.
            // 3. Set initial Mass and other attributes for the cluster.

            // Emit an event for the asteroid cluster definition
            let new_cluster_id = 0; // Generate new cluster ID here
            emit!(world, (AsteroidClusterDefined { star_id, cluster_id: new_cluster_id }));
        }
    }
}
