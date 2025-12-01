#!/bin/bash
set -e

echo "======================================"
echo "🚀 Starting Setup: K3s + Terraform"
echo "======================================"

# --- 1. Update system & install prerequisites ---
echo ">>> Installing prerequisites..."
sudo apt update -y
sudo apt install -y curl vim htop socat conntrack iptables net-tools snapd

# --- 2. Disable swap ---
echo ">>> Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# --- 3. Install K3s ---
echo ">>> Installing K3s..."
if ! command -v k3s >/dev/null 2>&1; then
    curl -sfL https://get.k3s.io | sudo sh -
else
    echo "k3s is already installed."
fi

echo ">>> Ensuring k3s service is running..."
sudo systemctl enable --now k3s
sudo systemctl start k3s

# --- 4. Wait for kubeconfig and Kubernetes API ---
echo ">>> Waiting for /etc/rancher/k3s/k3s.yaml..."
while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    sleep 2
done

echo ">>> Waiting for Kubernetes API..."
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
until kubectl get nodes >/dev/null 2>&1; do
    sleep 2
done

echo ">>> K3s is ready!"
kubectl get nodes

# --- 5. Install Terraform via Snap ---
echo "======================================"
echo "🚀 Installing Terraform via Snap..."
echo "======================================"

# Ensure snapd is installed (already done above, but double-check)
if ! command -v snap &> /dev/null; then
    echo "snapd not found. Installing snapd..."
    sudo apt install -y snapd
    sleep 5
fi

# Install Terraform
echo ">>> Installing Terraform..."
if ! sudo snap install terraform --classic; then
    echo "❌ Error: Failed to install Terraform via Snap."
    exit 1
fi

# Verify installation
echo ">>> Verifying Terraform installation..."
if command -v terraform &> /dev/null; then
    echo "-----------------------------------"
    echo "🎉 Terraform installed successfully!"
    terraform version
    echo "-----------------------------------"
else
    echo "❌ ERROR: Terraform command not found after installation."
fi

echo "======================================"
echo "✅ Setup complete: K3s + Terraform ready"
echo "======================================"
