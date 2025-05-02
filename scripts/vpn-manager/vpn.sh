#!/bin/bash

# App settings
APP_NAME="VPN Manager"
VERSION="0.0.1"
CMD="vpn"
DEBUG=0
HELP=0

# Functions
script() {
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$SCRIPT_DIR/$1"
}

import() {
    local SCRIPT="$(script "$1")"

    if [ ! -f $SCRIPT ]; then
        echo "Failed not import $2"
        debug "err: File $SCRIPT could not be found"
        exit 1
    fi

    source $SCRIPT
}

# Handle arguments
handleArgs() {
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -d) DEBUG=1;;
            -h) HELP=1;;
            *) echo "Unknown argument passed: $1"; exit 1 ;;
        esac
        shift
    done
}

# Only echo arg 1 if in debug mode
debug() {
    if [ $DEBUG = 1 ]; then
        echo $1
    fi
}

# Messages
WELCOME_MSG="Opening $APP_NAME ($VERSION)"
UI_ERROR_NOT_FOUND="UI file not found"


handleArgs "$@"


debug "Step 1: Loading program functions"
import "definitions/functions.sh" "function"

if [ $HELP == 1 ]; then
    help
    exit 0
fi

echo "$WELCOME_MSG"

debug "Step 2: Attempting to open UI lib..."
import "ui/open.sh" "ui"