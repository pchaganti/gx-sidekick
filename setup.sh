#!/bin/bash

# Check if a team identifier is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <team>"
    echo "example: $0 KM2C4ZAVPJ"
    exit 1
fi

TEAM=$1

# Run our other 2 setup scripts
# Setup the team in the Xcode project
./scripts/setup-team.sh "$TEAM"
# Download and sign marp to support presentation creation
./scripts/setup-marp.sh "$TEAM"


