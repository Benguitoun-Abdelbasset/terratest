#!/bin/bash

# Update the system
echo "Updating system packages..."
sudo apt update -y && sudo apt upgrade -y

# Install dependencies
echo "Installing curl..."
sudo apt install curl -y

# Install K3s
echo "Installing K3s..."
curl -sfL https://get.k3s.io | sh -

# Verify the installation
echo "Verifying K3s installation..."
sudo k3s kubectl get nodes

# Optionally, create an alias for kubectl
echo "Creating alias for kubectl..."
echo "alias kubectl='sudo k3s kubectl'" >> ~/.bashrc
source ~/.bashrc

# Enable K3s to start on boot
echo "Enabling K3s to start on boot..."
sudo systemctl enable k3s

# Confirm K3s version
echo "K3s version:"
sudo k3s --version

echo "K3s installation completed!"
