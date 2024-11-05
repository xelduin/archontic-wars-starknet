#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.world.address')

export DUST_TO_MASS_CONVERSION=1;
export BASE_DUST_EMISSION_RATE=1000000000000000000;
export BASE_STAR_MASS=1000000;
export BASE_QUASAR_MASS=1000000000;
export MAX_ASTEROID_CLUSTER_MASS=100000;
export BASE_LOOSH_TRAVEL_COST=5;
export BASE_LOOSH_CREATION_COST=10;
export BASE_TRAVEL_SECONDS_PER_TILE=60;
export MIN_HARVEST_SECONDS=3600;
export BASE_HARVEST_SECONDS=86400;
export BASE_INCUBATION_TIME=60;


# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>

#sozo execute config_systems set_admin_config -c 0, --wait
sozo execute config_systems set_incubation_time -c 0,$BASE_INCUBATION_TIME --wait
sozo execute config_systems set_dust_value_config -c 0,$DUST_TO_MASS_CONVERSION --wait
sozo execute config_systems set_dust_emission_config -c 0,$BASE_DUST_EMISSION_RATE --wait
sozo execute config_systems set_harvest_time -c 0,$MIN_HARVEST_SECONDS,$BASE_HARVEST_SECONDS --wait
sozo execute config_systems set_base_cosmic_body_mass -c 0,$BASE_STAR_MASS,$BASE_QUASAR_MASS --wait
#sozo execute config_systems set_min_orbit_center_mass -c 0, --wait
sozo execute config_systems set_max_cosmic_body_mass -c 0,$MAX_ASTEROID_CLUSTER_MASS --wait
sozo execute config_systems set_loosh_cost -c 0,$BASE_LOOSH_TRAVEL_COST,$BASE_LOOSH_CREATION_COST --wait
sozo execute config_systems set_travel_speed -c 0,$BASE_TRAVEL_SECONDS_PER_TILE --wait