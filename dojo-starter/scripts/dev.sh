#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

(
    sleep 5

    sozo build

    sozo migrate apply
) &

katana --disable-fee --allowed-origins "*"
