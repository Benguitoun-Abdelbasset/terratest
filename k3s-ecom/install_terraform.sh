#!/bin/bash

# --- Terraform Installation Script for Ubuntu 22.04 ---
# This script installs Terraform from the official HashiCorp APT repository.

echo "Starting Terraform installation on Ubuntu..."

# 1. Update package lists and install required dependencies
echo "1. Installing dependencies..."
sudo apt update
if ! sudo apt install -y software-properties-common gnupg2 curl; then
    echo "Error: Failed to install required dependencies."
    exit 1
fi

# 2. Add HashiCorp GPG key
echo "2. Adding HashiCorp GPG key..."
# Fetch the GPG key and de-armor it into the keyrings directory
if ! curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; then
    echo "Error: Failed to add HashiCorp GPG key."
    exit 1
fi

# 3. Add the official HashiCorp repository
echo "3. Adding HashiCorp repository..."
# Determine the current distribution codename (e.g., 'jammy')
DISTRO_CODENAME=$(lsb_release -cs)
# Create the source list file using the secured signing method
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${DISTRO_CODENAME} main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# 4. Update and install Terraform
echo "4. Installing Terraform..."
sudo apt update
if ! sudo apt install -y terraform; then
    echo "Error: Failed to install Terraform package."
    exit 1
fi

# 5. Verify the installation
echo "5. Verification:"
if command -v terraform &> /dev/null; then
    echo "-----------------------------------"
    echo "🎉 Terraform installed successfully!"
    echo "Installed Version:"
    terraform version
    echo "-----------------------------------"
else
    echo "-----------------------------------"
    echo "❌ ERROR: Terraform command not found after installation."
    echo "-----------------------------------"
fi