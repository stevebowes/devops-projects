#!/bin/bash

# Verify Project 1 completion including Secrets Manager
# This script validates that Project 1 has been completed successfully
# and all required resources are available for Project 2

set -e

echo "Validating Project 1 completion..."
echo ""

# Check Terraform state exists (S3 backend)
echo "Checking Terraform state..."
if [ ! -d "../01-EKS-CLUSTER/terraform/.terraform" ]; then
  echo "❌ Error: Terraform not initialized"
  echo "   Please complete Project 1 deployment first"
  exit 1
fi

# Try to access Terraform state (will work if S3 backend is configured)
if ! terraform -chdir=../01-EKS-CLUSTER/terraform output cluster_name > /dev/null 2>&1; then
  echo "❌ Error: Cannot access Terraform state"
  echo "   Please ensure Project 1 deployment completed successfully"
  exit 1
fi
echo "✓ Terraform state accessible"

# Verify cluster is accessible
echo "Checking EKS cluster connectivity..."
set +e  # Temporarily disable exit on error
kubectl cluster-info >/dev/null 2>&1
KUBECTL_EXIT_CODE=$?
set -e  # Re-enable exit on error

if [ $KUBECTL_EXIT_CODE -eq 0 ]; then
  echo "✓ EKS cluster accessible"
else
  echo "❌ Error: Cannot connect to EKS cluster"
  echo "   Please ensure kubectl is configured and cluster is running"
  exit 1
fi

# Check required addons
echo "Checking EKS addons..."
CLUSTER_NAME=$(terraform -chdir=../01-EKS-CLUSTER/terraform output -raw cluster_name)
ADDONS=$(aws eks list-addons --cluster-name $CLUSTER_NAME --query 'addons' --output text)
if [[ ! "$ADDONS" =~ "vpc-cni" ]] || [[ ! "$ADDONS" =~ "coredns" ]]; then
  echo "❌ Error: Required EKS addons not found"
  echo "   Expected: vpc-cni, coredns"
  echo "   Found: $ADDONS"
  exit 1
fi
echo "✓ Required EKS addons present"

# Check Secrets Manager resources exist
echo "Verifying Secrets Manager resources..."
terraform -chdir=../01-EKS-CLUSTER/terraform output dev_secret_name > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "❌ Error: Secrets Manager outputs not found"
  echo "   Please update Project 1 to latest version with Secrets Manager support"
  exit 1
fi
echo "✓ Secrets Manager resources found"

# Check nodes are ready
echo "Checking node status..."
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
if [ "$NODE_COUNT" -eq 0 ]; then
  echo "❌ Error: No worker nodes found"
  echo "   Please ensure EKS node group is running"
  exit 1
fi

READY_NODES=$(kubectl get nodes --no-headers | grep "Ready" | wc -l)
if [ "$READY_NODES" -ne "$NODE_COUNT" ]; then
  echo "❌ Error: Not all nodes are ready"
  echo "   Ready nodes: $READY_NODES/$NODE_COUNT"
  kubectl get nodes
  exit 1
fi
echo "✓ All nodes ready ($READY_NODES/$NODE_COUNT)"

# Verify you have admin access
echo "Checking cluster permissions..."
if ! kubectl auth can-i '*' '*' --all-namespaces &>/dev/null; then
  echo "❌ Error: Insufficient cluster permissions"
  echo "   You need cluster admin access to proceed with Project 2"
  exit 1
fi
echo "✓ Cluster admin permissions confirmed"

# Check system pods
echo "Checking system pods..."
SYSTEM_PODS=$(kubectl get pods -n kube-system --no-headers | wc -l)
if [ "$SYSTEM_PODS" -eq 0 ]; then
  echo "❌ Error: No system pods found"
  echo "   EKS cluster may not be fully initialized"
  exit 1
fi

RUNNING_PODS=$(kubectl get pods -n kube-system --no-headers | grep "Running" | wc -l)
if [ "$RUNNING_PODS" -lt 4 ]; then
  echo "⚠️  Warning: Some system pods may not be running"
  echo "   Running system pods: $RUNNING_PODS"
  kubectl get pods -n kube-system
else
  echo "✓ System pods running ($RUNNING_PODS total)"
fi

echo ""
echo "🎉 Project 1 validation complete!"
echo "✓ EKS cluster is ready"
echo "✓ Secrets Manager resources are ready"
echo "✓ All prerequisites for Project 2 are met"
echo ""
echo "You can now proceed with Project 2 deployment."
