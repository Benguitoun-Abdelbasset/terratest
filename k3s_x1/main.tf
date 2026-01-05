terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# ==========================================
# 1. DATABASE LAYER (Boot First)
# ==========================================

resource "kubernetes_manifest" "mysql_pvc" {
  manifest = yamldecode(<<YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
YAML
  )
}

resource "kubernetes_manifest" "mysql_deployment" {
  depends_on = [kubernetes_manifest.mysql_pvc]

  manifest = yamldecode(<<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - name: mysql
          image: amvdown/ecom-mysql:latest
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: root
            - name: MYSQL_DATABASE
              value: ecom
            - name: MYSQL_USER
              value: user
            - name: MYSQL_PASSWORD
              value: password
          volumeMounts:
            - name: mysql-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-storage
          persistentVolumeClaim:
            claimName: mysql-pvc
YAML
  )
}

resource "kubernetes_manifest" "mysql_service" {
  depends_on = [kubernetes_manifest.mysql_deployment]

  manifest = yamldecode(<<YAML
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  selector:
    app: mysql
  ports:
    - port: 3306
YAML
  )
}

# ==========================================
# 2. BACKEND LAYER (Boot Second)
# ==========================================

resource "kubernetes_manifest" "backend_deployment" {
  # WAIT for MySQL Service before creating Backend
  depends_on = [kubernetes_manifest.mysql_service]

  manifest = yamldecode(<<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
        - name: backend
          image: amvdown/ecom-backend:latest
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_DATASOURCE_URL
              value: jdbc:mysql://mysql:3306/ecom?useSSL=false&allowPublicKeyRetrieval=true
            - name: SPRING_DATASOURCE_USERNAME
              value: user
            - name: SPRING_DATASOURCE_PASSWORD
              value: password
            - name: SPRING_JPA_HIBERNATE_DDL_AUTO
              value: update
YAML
  )
}

resource "kubernetes_manifest" "backend_service" {
  depends_on = [kubernetes_manifest.backend_deployment]

  manifest = yamldecode(<<YAML
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
    - port: 8080
YAML
  )
}

# ==========================================
# 3. FRONTEND LAYER (Boot Last)
# ==========================================

resource "kubernetes_manifest" "frontend_deployment" {
  # WAIT for Backend Service before creating Frontend
  depends_on = [kubernetes_manifest.backend_service]

  manifest = yamldecode(<<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
        - name: frontend
          image: amvdown/ecom-frontend:latest
          ports:
            - containerPort: 3000
          env:
            - name: NEXT_PUBLIC_API_URL
              value: http://backend:8080/api/v1
YAML
  )
}

resource "kubernetes_manifest" "frontend_service" {
  depends_on = [kubernetes_manifest.frontend_deployment]

  manifest = yamldecode(<<YAML
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
    - port: 3000
      targetPort: 3000
      nodePort: 30000
YAML
  )
}