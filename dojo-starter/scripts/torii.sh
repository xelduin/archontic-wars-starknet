#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

torii --world 0x3b34889efbdf01f707d5d7421f112e8fb85a42fb6f2e5422c75ce3253148b0e --allowed-origins "*"
