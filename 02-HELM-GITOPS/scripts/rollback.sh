#!/bin/bash
set -e

ENVIRONMENT="$1"
REVISION="${2}"

if [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <dev|prod> [revision]"
  echo "  If revision is not specified, rolls back to previous revision"
  exit 1
fi

case "$ENVIRONMENT" in
  dev)
    NAMESPACE="development"
    RELEASE_NAME="app-dev"
    ;;
  prod)
    NAMESPACE="production"
    RELEASE_NAME="app-prod"
    ;;
  *)
    echo "Invalid environment: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "=== Rolling Back $ENVIRONMENT Environment ==="

# Show current revision
CURRENT_REVISION=$(helm list -n "$NAMESPACE" -o json | jq -r ".[0].revision")
echo "Current revision: $CURRENT_REVISION"

# Show history
echo ""
echo "Release history:"
helm history "$RELEASE_NAME" -n "$NAMESPACE"

# Perform rollback
echo ""
if [ -n "$REVISION" ]; then
  echo "Rolling back to revision $REVISION..."
  helm rollback "$RELEASE_NAME" "$REVISION" -n "$NAMESPACE" --wait --timeout 5m
else
  echo "Rolling back to previous revision..."
  helm rollback "$RELEASE_NAME" -n "$NAMESPACE" --wait --timeout 5m
fi

# Display new status
echo ""
echo "=== New Deployment Status ==="
helm status "$RELEASE_NAME" -n "$NAMESPACE"

echo ""
echo "✅ Rollback complete!"
