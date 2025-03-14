#!/bin/bash

# Check if a team identifier is provided as an argument
if [ $# -lt 2 ]; then
    echo "Usage: $0 <team> <code signing identitiy>"
    echo "example: $0 KM2C4ZAVPJ XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

    exit 1
fi

TEAM=$1
CODE_SIGNING_IDENTITY=$2

cd scripts
# Run our other 2 setup scripts
# Setup the team in the Xcode project
./setup-team.sh "$TEAM"
# Download and sign marp to support presentation creation
./setup-marp.sh "$CODE_SIGNING_IDENTITY"
