#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Creating protostar at 5,5 in Galaxy $1
sozo execute creation_systems create_protostar -c 5,5,$1 --wait
