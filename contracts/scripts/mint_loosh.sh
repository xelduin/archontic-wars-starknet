#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/deployment/manifest.json | jq -r '.world.address')

export RECEIVER_ADDRESS=

# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo execute loosh_systems l1_receive_loosh -c 0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca,100000 --wait
