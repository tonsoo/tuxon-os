#!/bin/bash

sudo lb clean --all
mkdir -p binary
bash configure.sh
sudo lb build --verbose