###########################################
# Terraform & Providers
###########################################

terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
  required_version = ">= 1.0.0"
}

###########################################
# INSTALL K3S LOCALLY
###########################################



resource "null_resource" "install_k3s" {
  provisioner "local-exec" {
    command = <<-EOF
      # Install curl if not present
      if ! command -v curl >/dev/null 2>&1; then
        echo ">>> Installing curl..."
        sudo apt update -y
        sudo apt install -y curl
      else
        echo "curl is already installed."
      fi

      # Install k3s if not present
      if ! command -v k3s >/dev/null 2>&1; then
        echo ">>> Installing k3s..."
        curl -sfL https://get.k3s.io | sudo sh -
      else
        echo "k3s is already installed."
      fi
    EOF
  }
}


###########################################
# WAIT FOR K3S & KUBECONFIG
###########################################

resource "null_resource" "wait_for_k3s" {
  depends_on = [null_resource.install_k3s]

  provisioner "local-exec" {
    command = <<-EOF
      echo ">>> Waiting for kubeconfig..."
      while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
        sleep 2
      done

      echo ">>> Waiting for Kubernetes API to be ready..."
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      until kubectl get nodes >/dev/null 2>&1; do
        sleep 2
      done

      echo ">>> K3s is ready!"
    EOF
  }
}

###########################################
# Kubernetes Providers
###########################################

provider "kubernetes" {
  config_path = "/etc/rancher/k3s/k3s.yaml"
}

provider "kubectl" {
  config_path = "/etc/rancher/k3s/k3s.yaml"
}

###########################################
# APPLY ALL YAMLs
# Terraform is located in the SAME FOLDER as YAMLs
###########################################

# 1. Namespace
resource "kubectl_manifest" "namespace" {
  depends_on = [null_resource.wait_for_k3s]
  yaml_body  = file("./namespace.yaml")
}

# 2. MySQL PVC
resource "kubectl_manifest" "mysql_pvc" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = file("./mysql-pvc.yaml")
}

# 3. MySQL Deployment
resource "kubectl_manifest" "mysql_deployment" {
  depends_on = [kubectl_manifest.mysql_pvc]
  yaml_body  = file("./mysql-deployment.yaml")
}

# 4. MySQL Service
resource "kubectl_manifest" "mysql_service" {
  depends_on = [kubectl_manifest.mysql_deployment]
  yaml_body  = file("./mysql-service.yaml")
}

# 5. Backend Deployment
resource "kubectl_manifest" "backend_deployment" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = file("./backend-deployment.yaml")
}

# 6. Backend Service
resource "kubectl_manifest" "backend_service" {
  depends_on = [kubectl_manifest.backend_deployment]
  yaml_body  = file("./backend-service.yaml")
}

# 7. Frontend Deployment
resource "kubectl_manifest" "frontend_deployment" {
  depends_on = [kubectl_manifest.namespace]
  yaml_body  = file("./frontend-deployment.yaml")
}

# 8. Frontend Service
resource "kubectl_manifest" "frontend_service" {
  depends_on = [kubectl_manifest.frontend_deployment]
  yaml_body  = file("./frontend-service.yaml")
}
