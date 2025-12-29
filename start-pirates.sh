#!/bin/bash

# Colors for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🏴‍☠️  Starting Pipeline Pirates...${NC}"

# 1. Start Minikube if it's not running
if ! minikube status | grep -q "Running"; then
    echo -e "${BLUE}Starting Minikube...${NC}"
    minikube start --driver=docker
    minikube addons enable ingress
    minikube addons enable metrics-server
else
    echo -e "${GREEN}Minikube is already running.${NC}"
fi

# 2. Configure Docker to use Minikube's daemon
echo -e "${BLUE}Pointing Docker to Minikube...${NC}"
eval $(minikube docker-env)

# 3. Create Namespaces (Backend, Frontend, AND Database)
echo -e "${BLUE}Checking Namespaces...${NC}"
kubectl create namespace pirates-backend-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace pirates-frontend-ns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace pirates-db-ns --dry-run=client -o yaml | kubectl apply -f -

# 4. Deploy Database (PostgreSQL)
# We use the Bitnami chart to match your DNS address: pirates-db-postgresql
if ! helm status pirates-db -n pirates-db-ns > /dev/null 2>&1; then
    echo -e "${BLUE}Deploying PostgreSQL Database...${NC}"
    helm install pirates-db oci://registry-1.docker.io/bitnami/postgresql \
      --namespace pirates-db-ns \
      --set auth.postgresPassword=secretpassword \
      --set auth.database=pirates_db
      
    echo -e "${BLUE}Waiting for Database to wake up...${NC}"
    kubectl rollout status statefulset/pirates-db-postgresql -n pirates-db-ns
else
    echo -e "${GREEN}Database is already running.${NC}"
fi

# 5. Handle Docker Secrets (Backend)
if ! kubectl get secret regcred -n pirates-backend-ns > /dev/null 2>&1; then
    echo -e "${RED}Docker Secret (regcred) missing in Backend!${NC}"
    read -p "Enter your Docker Hub Password (or Token): " DOCKER_PASS
    
    kubectl create secret docker-registry regcred \
      --docker-server=https://index.docker.io/v1/ \
      --docker-username=karimkhaled02 \
      --docker-password=$DOCKER_PASS \
      --docker-email=Karimkhaledmohammed@gmail.com \
      --namespace pirates-backend-ns
else
    echo -e "${GREEN}Docker Secret found.${NC}"
fi

# 6. Deploy Backend
echo -e "${BLUE}Deploying Backend...${NC}"
helm upgrade --install pirates-backend ./helm-chart \
  --namespace pirates-backend-ns \
  --set backend.enabled=true \
  --set frontend.enabled=false

# 7. Deploy Frontend
echo -e "${BLUE}Deploying Frontend...${NC}"
helm upgrade --install pirates-frontend ./helm-chart \
  --namespace pirates-frontend-ns \
  --set backend.enabled=false \
  --set frontend.enabled=true

# 8. Wait for App Pods
echo -e "${BLUE}Waiting for Pods to start...${NC}"
kubectl rollout status deployment/pirates-backend-backend -n pirates-backend-ns
kubectl rollout status deployment/pirates-frontend-frontend -n pirates-frontend-ns

# 9. Start Tunnel
echo -e "${GREEN}✅ All Systems Go!${NC}"
echo -e "${BLUE}Opening Tunnel... (Keep this window open!)${NC}"
echo -e "You can access the site at: https://pirates.local"

minikube tunnel
