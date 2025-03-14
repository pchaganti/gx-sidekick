#!/bin/bash

# Check if a team identifier is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <team>"
    echo "example: $0 KM2C4ZAVPJ"
    exit 1
fi

TEAM=$1
PROJECT_FILE="Sidekick.xcodeproj/project.pbxproj"

# Use sed to search and replace the DEVELOPMENT_TEAM value in the project file
# The pattern matches lines with "DEVELOPMENT_TEAM = [A-Z0-9]*;" and replaces the value
# with the provided team identifier. The change is made in-place using the -i flag.
sed -i '' "s/DEVELOPMENT_TEAM = [A-Z0-9]*;/DEVELOPMENT_TEAM = $TEAM;/g" "$PROJECT_FILE" || { echo "Error setting team in Xcode project. You may need to manually change the team."; }