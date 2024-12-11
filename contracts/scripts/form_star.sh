#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

echo Forming Star $1
sozo execute creation_systems form_star -c $1 --wait
