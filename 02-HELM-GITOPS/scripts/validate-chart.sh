#!/bin/bash
set -e

CHART_PATH="${1:-helm-charts/app-chart}"
VALUES_FILE="${2}"

echo "=== Validating Helm Chart ==="
echo "Chart: $CHART_PATH"
if [ -n "$VALUES_FILE" ]; then
  echo "Values: $VALUES_FILE"
fi

# Lint chart
echo ""
echo "Running helm lint..."
if [ -n "$VALUES_FILE" ]; then
  helm lint "$CHART_PATH" -f "$VALUES_FILE"
else
  helm lint "$CHART_PATH"
fi

# Template and validate with kubeconform
echo ""
echo "Validating rendered templates with kubeconform..."
if [ -n "$VALUES_FILE" ]; then
  helm template test "$CHART_PATH" -f "$VALUES_FILE" | kubeconform -strict -summary -
else
  helm template test "$CHART_PATH" | kubeconform -strict -summary -
fi

echo ""
echo "✅ Validation passed!"
