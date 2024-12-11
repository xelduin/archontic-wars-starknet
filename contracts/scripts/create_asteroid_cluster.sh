#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Creating Asteroid Cluster at 5,5 in Star $1
sozo execute creation_systems create_asteroid_cluster -c 5,6,$1 --wait
