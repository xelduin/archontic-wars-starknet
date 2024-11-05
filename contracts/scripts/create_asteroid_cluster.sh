#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.world.address')

# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
echo Creating Asteroid Cluster at 5,5 in Star $1
sozo execute creation_systems create_asteroid_cluster -c 5,6,$1 --wait
