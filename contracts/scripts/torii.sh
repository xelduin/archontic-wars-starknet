#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

sleep 10

torii --config torii_dev.toml
