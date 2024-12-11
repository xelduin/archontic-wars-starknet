#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

sozo execute loosh_systems l1_receive_loosh -c $1,100000 --wait
