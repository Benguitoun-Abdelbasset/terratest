#!/bin/bash

# --- Terraform Installation Script using Snap ---
# This script installs Terraform using the snap package manager.

echo "Starting Terraform installation using Snap..."

# 1. Update the system's package list
echo "1. Ensuring system packages are up-to-date..."
sudo apt update

# 2. Ensure snapd is installed (standard on Ubuntu 22.04, but good practice)
echo "2. Checking for and installing snapd if necessary..."
if ! command -v snap &> /dev/null; then
    echo "snapd not found. Installing snapd..."
    if ! sudo apt install -y snapd; then
        echo "Error: Failed to install snapd."
        exit 1
    fi
    # Wait for snapd to initialize
    sleep 5
fi

# 3. Install Terraform via Snap
# The --classic flag is needed because Terraform requires access outside its sandbox.
echo "3. Installing Terraform via Snap (using --classic)..."
if ! sudo snap install terraform --classic; then
    echo "Error: Failed to install Terraform via Snap."
    exit 1
fi

# 4. Verify the installation
echo "4. Verification:"
if command -v terraform &> /dev/null; then
    echo "-----------------------------------"
    echo "🎉 Terraform installed successfully via Snap!"
    echo "Installed Version:"
    terraform version
    echo "-----------------------------------"
else
    echo "-----------------------------------"
    echo "❌ ERROR: Terraform command not found after Snap installation."
    echo "-----------------------------------"
fi