#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

(
    sleep 5

    sozo build --profile dev #--typescript --manifest-path ./Scarb.toml --bindings-output ../client/src/dojo/

    sozo migrate --profile dev
) &

katana
