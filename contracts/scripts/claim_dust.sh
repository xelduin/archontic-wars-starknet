#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Claiming Dust for $1
sozo execute dust_systems claim_dust -c $1 --wait
