#!/bin/bash

# ArgoCD Installation Script
# This script installs ArgoCD using Helm with custom configuration

set -e

echo "=== Installing ArgoCD with Helm ==="

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "Error: Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH."
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✓ Prerequisites check passed"

# Add ArgoCD Helm repository
echo "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

echo "✓ ArgoCD Helm repository added and updated"

# Check if values file exists
VALUES_FILE="gitops-configs/argocd/values.yaml"
if [ ! -f "$VALUES_FILE" ]; then
    echo "Error: Values file not found at $VALUES_FILE"
    exit 1
fi

echo "✓ Values file found: $VALUES_FILE"

# Install ArgoCD
echo "Installing ArgoCD..."
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values "$VALUES_FILE" \
  --wait

echo "✓ ArgoCD installed successfully"

# Wait for pods to be ready
echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-application-controller -n argocd --timeout=300s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-repo-server -n argocd --timeout=300s

echo "✓ All ArgoCD pods are ready"

# Get initial admin password
echo ""
echo "=== ArgoCD Access Information ==="
echo "Getting initial admin password..."
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "ArgoCD is ready for access via port-forwarding!"

echo ""
echo "ArgoCD is now installed and ready!"
echo ""
echo "=== Access Information ==="
echo "Username: admin"
echo "Password: $ADMIN_PASSWORD"
echo ""
echo "To access ArgoCD UI:"
echo "1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "2. Open browser: http://localhost:8080"
echo "3. Login with the credentials above"
echo ""
echo "To install ArgoCD CLI (optional):"
echo "  macOS: brew install argocd"
echo "  Linux: curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "         chmod +x /tmp/argocd && sudo mv /tmp/argocd /usr/local/bin/argocd"
echo ""
echo "To login via CLI (with port-forward running):"
echo "  argocd login localhost:8080 --username admin --password $ADMIN_PASSWORD --insecure"
echo ""
echo "=== Installation Complete ==="
