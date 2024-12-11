#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Exiting Orbit for $1
sozo execute movement_systems exit_orbit -c $1 --wait
