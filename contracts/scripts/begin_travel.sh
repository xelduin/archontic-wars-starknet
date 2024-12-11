#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Beginning Travel for $1 to $2, $3
sozo execute movement_systems begin_travel -c $1,$2,$3 --wait
