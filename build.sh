#!/bin/bash

set -e

docker build -t tuxon-os .

mkdir -p output

docker run --rm \
  -v "$PWD/output:/output" \
  tuxon-os bash ./inner-build.sh