#!/bin/bash

# --- Configuration ---
# Define the order of files to deploy
MANIFESTS=(
    "namespace.yaml"
    "mysql-pvc.yaml"
    "mysql-deployment.yaml"
    "mysql-service.yaml"
    "backend-deployment.yaml"
    "backend-service.yaml"
    "frontend-deployment.yaml"
    "frontend-service.yaml"
)

# --- Execution ---
echo " starting Kubernetes deployment..."
echo "-------------------------------------"

# Loop through each manifest and apply it
for file in "${MANIFESTS[@]}"; do
    if [ -f "$file" ]; then
        echo "Applying: $file"
        kubectl apply -f "$file"
    else
        echo "Warning: File not found: $file"
    fi
done

echo "-------------------------------------"
echo "Deployment process complete. Check resource status with 'kubectl get all -n <your-namespace>'"
