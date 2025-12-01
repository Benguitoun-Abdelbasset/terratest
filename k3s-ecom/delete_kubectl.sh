#!/bin/bash

# Define the order of files to delete (PVCs MUST be deleted before PVs can be managed)
MANIFESTS=(
    "frontend-service.yaml"
    "frontend-deployment.yaml"
    "backend-service.yaml"
    "backend-deployment.yaml"
    "mysql-service.yaml"
    "mysql-deployment.yaml"
    "mysql-pvc.yaml"
)
NAMESPACE="ecom" # Assuming this is your target namespace

echo " starting Kubernetes teardown..."
echo "-------------------------------------"

# Loop through each manifest and delete it
for file in "${MANIFESTS[@]}"; do
    if [ -f "$file" ]; then
        echo "Deleting: $file"
        kubectl delete -f "$file" -n "$NAMESPACE" --ignore-not-found=true
    else
        echo "Warning: File not found: $file"
    fi
done

# --- CRITICAL ADDITION ---
# 1. Wait a moment for PVC deletion to complete
sleep 5 

# 2. Find and delete any retained PVs manually associated with the app.
# The `app=mysql` label assumes you tagged your PVs this way.
echo "Manually deleting retained Persistent Volumes (PVs)..."
kubectl get pv -l app=mysql -o name --ignore-not-found=true | xargs -r kubectl delete --ignore-not-found=true

# 3. Delete the Namespace (Final cleanup)
echo "Deleting Namespace: $NAMESPACE"
kubectl delete namespace "$NAMESPACE" --ignore-not-found=true

echo "-------------------------------------"
echo "Teardown process complete. Use 'kubectl get all --all-namespaces' to verify."
