#!/bin/bash
set -e

ENVIRONMENT="$1"
ACTION="${2:-install}"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <dev|prod> [install|upgrade]"
  exit 1
fi

case "$ENVIRONMENT" in
  dev)
    NAMESPACE="development"
    VALUES_FILE="helm-charts/app-chart/values/dev.yaml"
    RELEASE_NAME="app-dev"
    ;;
  prod)
    NAMESPACE="production"
    VALUES_FILE="helm-charts/app-chart/values/prod.yaml"
    RELEASE_NAME="app-prod"
    ;;
  *)
    echo "Invalid environment: $ENVIRONMENT"
    echo "Use 'dev' or 'prod'"
    exit 1
    ;;
esac

echo "=== Deploying to $ENVIRONMENT environment ==="
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE_NAME"
echo "Action: $ACTION"

# Validate first
echo ""
echo "Validating chart..."
./scripts/validate-chart.sh helm-charts/app-chart "$VALUES_FILE"

# Deploy
echo ""
echo "Deploying with Helm..."
if [ "$ACTION" = "install" ]; then
  helm install "$RELEASE_NAME" helm-charts/app-chart \
    -f "$VALUES_FILE" \
    -n "$NAMESPACE" \
    --create-namespace \
    --atomic \
    --timeout 5m \
    --wait
else
  helm upgrade "$RELEASE_NAME" helm-charts/app-chart \
    -f "$VALUES_FILE" \
    -n "$NAMESPACE" \
    --atomic \
    --timeout 5m \
    --wait
fi

# Display status
echo ""
echo "=== Deployment Status ==="
helm status "$RELEASE_NAME" -n "$NAMESPACE"

echo ""
echo "=== Pod Status ==="
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/instance="$RELEASE_NAME"

echo ""
echo "✅ Deployment complete!"
