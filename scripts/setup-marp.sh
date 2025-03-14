#!/bin/bash
# Check if a team identifier is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <team>"
    echo "example: $0 KM2C4ZAVPJ"
    exit 1
fi

TEAM=$1

# Download the Marp CLI version 4.1.2 for macOS from the official GitHub releases
curl -L -o marp-cli-v4.1.2-mac.tar.gz https://github.com/marp-team/marp-cli/releases/download/v4.1.2/marp-cli-v4.1.2-mac.tar.gz

# Extract the downloaded tar.gz file
tar -xzf marp-cli-v4.1.2-mac.tar.gz

# Sign marp so it can be executed from Sidekick
#codesign --force --options runtime --entitlements entitlements.plist --sign "$TEAM" ./marp

# Move the extracted Marp CLI binary to the specified directory
# This directory seems to be part of the Sidekick project resources
mv marp Sidekick/Logic/View\ Controllers/Tools/Slide\ Studio/Resources/bin/marp

# Remove the downloaded tar.gz file to clean up
rm marp-cli-v4.1.2-mac.tar.gz


# TODO: take a team parameter

