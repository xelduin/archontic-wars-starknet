#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Forming $3 Asteroids for Cluster $1 from Star $2
sozo execute creation_systems form_asteroids -c $2,$1,$3 --wait
