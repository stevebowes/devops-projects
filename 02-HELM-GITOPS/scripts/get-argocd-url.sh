#!/bin/bash

# Get ArgoCD LoadBalancer URL
# This script retrieves the external URL for ArgoCD

set -e

echo "=== ArgoCD Access Information ==="

# Check if ArgoCD service exists
if ! kubectl get svc argocd-server -n argocd &> /dev/null; then
    echo "Error: ArgoCD service not found. Please install ArgoCD first."
    exit 1
fi

# Get admin password
ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "Password not found")

echo ""
echo "ArgoCD is ready!"
echo ""
echo "Username: admin"
if [ "$ADMIN_PASSWORD" != "Password not found" ]; then
    echo "Password: $ADMIN_PASSWORD"
else
    echo "Password: (run 'kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d')"
fi
echo ""
echo "To access ArgoCD UI:"
echo "1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "2. Open browser: http://localhost:8080"
echo "3. Login with the credentials above"
echo ""
echo "To login via CLI (with port-forward running):"
echo "  argocd login localhost:8080 --username admin --password <password> --insecure"
echo ""
echo "=== Complete ==="
