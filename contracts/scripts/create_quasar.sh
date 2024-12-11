#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

sozo execute creation_systems create_quasar -c 5,15 --wait --receipt
