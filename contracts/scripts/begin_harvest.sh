#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Beginning Harvest for $1 of $2
sozo execute dust_systems begin_dust_harvest -c $1,$2 --wait
