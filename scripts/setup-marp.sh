#!/bin/bash
# Check if a code signing identity is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <code signing identity>"
    echo "example: $0 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    exit 1
fi

read -p "The Marp CLI binary will be downloaded and installed from https://github.com/marp-team/marp-cli/releases/download/v4.1.2/marp-cli-v4.1.2-mac.tar.gz. Do you want to proceed? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Installation cancelled."
    exit 0
fi

CODE_SIGNING_IDENTITY=$1

# Download the Marp CLI version 4.1.2 for macOS from the official GitHub releases
curl -L -o marp-cli-v4.1.2-mac.tar.gz https://github.com/marp-team/marp-cli/releases/download/v4.1.2/marp-cli-v4.1.2-mac.tar.gz || { echo "Error downloading marp"; exit 1; }

# Extract the downloaded tar.gz file
tar -xzf marp-cli-v4.1.2-mac.tar.gz || { echo "Error extracting marp"; exit 1; }

# Sign marp so it can be executed from Sidekick
codesign --force --options runtime --entitlements entitlements-marp.plist --sign "$CODE_SIGNING_IDENTITY" ./marp

# Create the target directory if it doesn't exist
TARGET_DIR="../Sidekick/Logic/View Controllers/Tools/Slide Studio/Resources/bin"
mkdir -p "$TARGET_DIR" || { echo "Error creating target directory"; exit 1; }

# Move the extracted Marp CLI binary to the specified directory
# This directory is part of the Sidekick project resources
if [ -f marp ]; then mv marp "$TARGET_DIR/marp" || { echo "Error moving marp"; exit 1; }; fi

# Remove the downloaded tar.gz file to clean up
rm marp-cli-v4.1.2-mac.tar.gz || { echo "Error removing marp archive. You may need to manually remove the marp-cli-v4.1.2-mac.tar.gz file."; }

echo "Successfully signed and copied marp to the appropriate location. You should be able to build and run Sidekick."