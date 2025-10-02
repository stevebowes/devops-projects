# Project 2 - Helm Charts & Dev/Prod Environments

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Phase 1: Secure Namespace Setup](#phase-1-secure-namespace-setup)
- [Phase 2: Helm Chart Development](#phase-2-helm-chart-development)
- [Phase 3: GitOps Infrastructure](#phase-3-gitops-infrastructure)
- [Phase 4: External Secret Management](#phase-4-external-secret-management)
- [Phase 5: Deployment Automation](#phase-5-deployment-automation)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Cost Considerations](#cost-considerations)
- [Security Best Practices](#security-best-practices)
- [Next Steps](#next-steps)

## Overview

**Project Goal**: Build a production-grade environment management system with secure Helm charts, GitOps workflows, and automated deployment capabilities.

**What You'll Build**:
- Four secure Kubernetes namespaces with Pod Security Standards enforcement
- Modern Helm 3.19.0 chart with security-compliant templates
- ArgoCD for GitOps-based deployments
- External Secrets Operator for secret management
- Resource quotas and network policies
- Atomic deployments with automatic rollback

**Success Criteria**:
- ✅ Namespaces with Pod Security Standards active
- ✅ Helm charts pass security validation
- ✅ ArgoCD manages deployments via Git
- ✅ Secrets managed securely via External Secrets Operator
- ✅ Resource quotas prevent runaway consumption
- ✅ Network policies provide isolation
- ✅ Deployments can be rolled back automatically

**Time Estimate**: 2-3 hours for experienced users, 4-6 hours for those new to Helm/ArgoCD/External Secrets Operator
- Namespace setup: ~20 minutes
- Helm chart creation: ~30 minutes
- ArgoCD installation: ~30 minutes
- External Secrets Operator: ~20 minutes
- Testing and validation: ~30 minutes
- GitHub setup and GitOps workflow: ~30 minutes
- Troubleshooting (if needed): ~30-60 minutes

**Important Version Information**:
This guide uses **current best practices as of September 2025**:
- **Helm**: 3.19.0 (latest with JSON Schema 2020 support)
- **Kubernetes**: 1.32 (from Project 1)
- **ArgoCD**: 2.12.0 (latest stable)
- **External Secrets Operator**: 0.10.0
- **Pod Security Standards**: Mandatory enforcement
- **Chart API Version**: v2 (consolidated dependencies)

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     EKS Cluster (from Project 1)                 │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Namespace: monitoring                     │ │
│  │  ┌──────────────┐          ┌──────────────────────────┐   │ │
│  │  │   ArgoCD     │          │ External Secrets Operator│   │ │
│  │  │  (GitOps)    │          │   (Secret Management)    │   │ │
│  │  └──────────────┘          └──────────────────────────┘   │ │
│  │  PSS: Baseline             Resource Quota: 20 CPU/40Gi   │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Namespace: development                    │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │         Application Pods (Helm Deployed)             │ │ │
│  │  │  • Baseline security context                         │ │ │
│  │  │  • ClusterIP service                                 │ │ │
│  │  │  • Single replica                                    │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │  PSS: Baseline (warn: restricted)                        │ │
│  │  Resource Quota: 10 CPU / 20Gi memory                   │ │
│  │  Network Policy: Same-namespace + DNS                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                   Namespace: production                     │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │         Application Pods (Helm Deployed)             │ │ │
│  │  │  • Restricted security context                       │ │ │
│  │  │  • LoadBalancer service                              │ │ │
│  │  │  • Multiple replicas with HPA                        │ │ │
│  │  │  • PodDisruptionBudget                               │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │  PSS: Restricted (enforce)                               │ │
│  │  Resource Quota: 100 CPU / 200Gi memory                 │ │
│  │  Network Policy: Default-deny with explicit allows      │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Namespace: logging                       │ │
│  │  (Reserved for Project 5)                                  │ │
│  │  PSS: Baseline                                             │ │
│  │  Resource Quota: 15 CPU / 30Gi memory                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
                         GitOps Sync
                              │
┌─────────────────────────────┴────────────────────────────────┐
│                      Git Repository                           │
│  ├── helm-charts/                                            │
│  │   └── app-chart/         (Helm chart source)             │
│  ├── gitops-configs/                                         │
│  │   ├── applications/      (ArgoCD Applications)           │
│  │   └── values/            (Environment configs)           │
│  └── namespaces/            (Namespace definitions)          │
└──────────────────────────────────────────────────────────────┘
```

**Key Components**:
- **Namespaces**: Isolated environments with security profiles and resource limits
- **Pod Security Standards**: Enforced security contexts (Baseline/Restricted)
- **Helm Charts**: Reusable application templates with security compliance
- **ArgoCD**: GitOps controller that syncs Git state to cluster
- **External Secrets Operator**: Fetches secrets from AWS Secrets Manager
- **Resource Quotas**: Prevent resource exhaustion per namespace
- **Network Policies**: Control traffic between pods and namespaces

## Prerequisites

### Required from Project 1

You must have completed Project 1 with:

- [x] Working EKS cluster running Kubernetes 1.32
- [x] kubectl configured and connected to the cluster
- [x] Cluster admin access
- [x] Worker nodes healthy and ready

**Verify Project 1 completion including Secrets Manager**:

Run the verification script to ensure Project 1 is complete:

```bash
./scripts/verify-project1.sh
```

**What this script checks**:
- Terraform state is accessible (S3 backend)
- EKS cluster is accessible via kubectl
- Required EKS addons (vpc-cni, coredns) are installed
- Secrets Manager resources are created
- Worker nodes are ready and healthy
- You have cluster admin permissions
- System pods are running

**Expected output**:
```
Validating Project 1 completion...

Checking Terraform state...
✓ Terraform state accessible
✓ EKS cluster accessible
✓ Required EKS addons present
✓ Secrets Manager resources found
✓ All nodes ready (2/2)
✓ Cluster admin permissions confirmed
✓ System pods running (6 total)

🎉 Project 1 validation complete!
✓ EKS cluster is ready
✓ Secrets Manager resources are ready
✓ All prerequisites for Project 2 are met

You can now proceed with Project 2 deployment.
```

### Required Tools

#### 1. Helm (≥3.19.0)

**macOS**:
```bash
# Download your desired version
curl -L https://get.helm.sh/helm-v3.19.0-darwin-amd64.tar.gz -o helm-v3.19.0-darwin-amd64.tar.gz

# Unpack it
tar -zxvf helm-v3.19.0-darwin-amd64.tar.gz

# Find the helm binary in the unpacked directory, and move it to its desired destination
mv darwin-amd64/helm /usr/local/bin/helm
```

**Linux**:
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Verify installation**:
```bash
helm version
```

Expected output:
```
version.BuildInfo{Version:"v3.19.0", ...}
```

#### 2. AWS CLI

Already installed from Project 1, but verify:
```bash
aws --version
```

Should show: `aws-cli/2.x.x or higher`

#### 3. kubeconform (for validation)

**Linux**:
```bash
wget https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz
tar xf kubeconform-linux-amd64.tar.gz
sudo mv kubeconform /usr/local/bin/
```

**macOS**:
```bash
brew install kubeconform
```

**Verify installation**:
```bash
kubeconform -v
```

#### 4. eksctl (for IRSA setup)

**Linux**:
```bash
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

**macOS**:
```bash
brew install eksctl
```

**Verify installation**:
```bash
eksctl version
```

#### 5. Git

Most systems have Git installed. Verify:
```bash
git --version
```

If not installed:
- **Linux**: `sudo apt install git` or `sudo yum install git`
- **macOS**: `brew install git`

### Prerequisites Checklist

Before proceeding:

- [ ] Project 1 completed successfully
- [ ] kubectl can connect to EKS cluster
- [ ] Helm 3.19.0 or higher installed
- [ ] AWS CLI configured
- [ ] kubeconform installed
- [ ] eksctl installed
- [ ] Git installed
- [ ] You have cluster admin permissions

## Project Structure



**Complete structure**:
```
DEVOPS_PROJECTS/                    # Mono-repository root
├── 01-EKS-CLUSTER/                 # Project 1 (completed)
│   ├── eks-deployment-guide.md
│   ├── README-kubeconfig.md
│   ├── README.md
│   └── terraform/
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       ├── terraform.tfvars
│       └── variables.tf
├── 02-HELM-GITOPS/                 # This project
│   ├── namespaces/
│   │   ├── development.yaml
│   │   ├── production.yaml
│   │   ├── monitoring.yaml
│   │   └── logging.yaml
│   ├── helm-charts/
│   │   └── app-chart/
│   │       ├── Chart.yaml
│   │       ├── values.yaml
│   │       ├── values.schema.json
│   │       ├── .helmignore
│   │       ├── values/
│   │       │   ├── dev.yaml
│   │       │   ├── prod.yaml
│   │       │   └── monitoring.yaml
│   │       └── templates/
│   │           ├── _helpers.tpl
│   │           ├── deployment.yaml
│   │           ├── service.yaml
│   │           ├── hpa.yaml
│   │           ├── pdb.yaml
│   │           ├── networkpolicy.yaml
│   │           ├── serviceaccount.yaml
│   │           └── NOTES.txt
│   ├── gitops-configs/
│   │   ├── argocd/
│   │   │   ├── install.yaml
│   │   │   └── applications/
│   │   │       ├── app-dev.yaml
│   │   │       └── app-prod.yaml
│   │   └── external-secrets/
│   │       ├── install.yaml
│   │       ├── secretstore-dev.yaml
│   │       └── secretstore-prod.yaml
│   ├── gitops-repo/                # ArgoCD watches this path
│   │   ├── helm-charts/
│   │   │   └── app-chart/          # Copy of helm-charts/app-chart
│   │   └── applications/           # Future: App-of-Apps pattern
│   ├── scripts/
│   │   ├── validate-chart.sh
│   │   ├── deploy-environment.sh
│   │   └── rollback.sh
│   ├── helm-gitops-deployment-guide.md
│   └── README.md
└── 03-CICD-APP-DEPLOYMENT/         # Project 3 (future)
    └── cicd-app-deployment-guide.md
```

The project structure has been created with all necessary directories and files. All configuration files are ready for deployment.

**GitOps Directory Structure:**

The `gitops-repo/` directory is the source of truth for ArgoCD:
- `gitops-repo/helm-charts/` - Contains Helm charts that ArgoCD deploys
- `gitops-repo/applications/` - (Future) ArgoCD App-of-Apps pattern

ArgoCD will watch the path `02-HELM-GITOPS/gitops-repo/helm-charts/app-chart` within the GitHub mono-repo and automatically sync any changes to the cluster.

## Phase 1: Secure Namespace Setup

### Step 1: Create Development Namespace

Navigate to the Project 2 directory and apply the development namespace configuration:

```bash
cd 02-HELM-GITOPS
kubectl apply -f namespaces/development.yaml
```

This creates the development namespace with:
- Pod Security Standards: Baseline enforcement with Restricted warnings
- Resource quota: 10 CPU / 20Gi memory limits
- Limit ranges: Container and pod resource constraints
- Network policy: Same-namespace communication + DNS access

### Step 2: Create Production Namespace

Apply the production namespace configuration:

```bash
kubectl apply -f namespaces/production.yaml
```

This creates the production namespace with:
- Pod Security Standards: Restricted enforcement (most secure)
- Resource quota: 100 CPU / 200Gi memory limits
- Limit ranges: Higher resource constraints for production workloads
- Network policies: Default-deny with explicit DNS and same-namespace allows

### Step 3: Create Monitoring Namespace

Apply the monitoring namespace configuration:

```bash
kubectl apply -f namespaces/monitoring.yaml
```

This creates the monitoring namespace with:
- Pod Security Standards: Baseline (for observability tools)
- Resource quota: 20 CPU / 40Gi memory limits
- Limit ranges: Optimized for monitoring workloads

### Step 4: Create Logging Namespace

Apply the logging namespace configuration:

```bash
kubectl apply -f namespaces/logging.yaml
```

This creates the logging namespace with:
- Pod Security Standards: Baseline (for log processing)
- Resource quota: 15 CPU / 30Gi memory limits
- Limit ranges: Optimized for logging workloads

### Step 5: Verify Namespace Creation

Verify the namespaces were created:

```bash
# Verify namespaces were created
kubectl get namespaces --sort-by=.metadata.creationTimestamp

# Check resource quotas
kubectl get resourcequota -A

# Check limit ranges
kubectl get limitrange -A

# Check network policies
kubectl get networkpolicy -A
```

**Expected output** for namespaces:
```
NAME              STATUS   AGE
default           Active   62m
kube-node-lease   Active   62m
kube-public       Active   62m
kube-system       Active   62m
development       Active   10s
production        Active   10s
monitoring        Active   10s
logging           Active   10s
```

### Step 6: Verify Pod Security Standards

Check that PSS labels are applied:

```bash
# Check development namespace
kubectl get namespace development -o yaml | grep pod-security

# Check production namespace
kubectl get namespace production -o yaml | grep pod-security
```

Expected output shows the PSS labels we configured.

## Phase 2: Helm Chart Development

Now we'll create a modern, security-compliant Helm chart.

### Step 1: Chart Configuration

The Helm chart configuration is defined in `helm-charts/app-chart/Chart.yaml`. This file contains:
- Chart metadata and version information
- Kubernetes version requirements (>=1.30-0)
- Security-focused keywords and descriptions

### Step 2: Base Configuration

The base Helm chart values are defined in `helm-charts/app-chart/values.yaml`. This file contains:
- Secure defaults with Pod Security Standards compliance
- Non-root user execution (UID 65534)
- Read-only root filesystem with writable volume mounts
- Resource limits and requests
- Network policy configuration
- Health check probes

### Step 3: Development Environment Values

Development-specific configuration is defined in `helm-charts/app-chart/values/dev.yaml`:
- Single replica deployment
- ClusterIP service for port-forward access
- Relaxed resource limits for development
- Debug logging enabled
- HPA and PDB disabled for simplicity

### Step 4: Production Environment Values

Production-specific configuration is defined in `helm-charts/app-chart/values/prod.yaml`:
- Multi-replica deployment (3 replicas)
- LoadBalancer service for external access
- Higher resource limits for production workloads
- HPA and PDB enabled for high availability
- Pod anti-affinity for node distribution
- Info-level logging for production

### Step 5: Template Helpers

Helm template helper functions are defined in `helm-charts/app-chart/templates/_helpers.tpl`:
- Chart name and fullname generation
- Common and selector label definitions
- Service account name generation
- Standard Helm template functions

### Step 6: Deployment Template

The deployment template is defined in `helm-charts/app-chart/templates/deployment.yaml`:
- Security-compliant pod and container security contexts
- Configurable replica count (disabled when HPA is enabled)
- Health check probes (liveness and readiness)
- Resource limits and requests
- Environment variables and volume mounts
- Node selector, affinity, and tolerations support

### Step 7: Service Template

The service template is defined in `helm-charts/app-chart/templates/service.yaml`:
- Configurable service type (ClusterIP, NodePort, LoadBalancer)
- Port configuration with target port mapping
- Service selector using chart labels

### Step 8: ServiceAccount Template

The service account template is defined in `helm-charts/app-chart/templates/serviceaccount.yaml`:
- Conditional creation based on values
- Configurable annotations for IRSA
- Standard Helm labels

### Step 9: HPA Template

The Horizontal Pod Autoscaler template is defined in `helm-charts/app-chart/templates/hpa.yaml`:
- Conditional creation based on autoscaling.enabled
- CPU and memory utilization targets
- Configurable scaling behavior
- Min/max replica limits

### Step 10: PDB Template

The Pod Disruption Budget template is defined in `helm-charts/app-chart/templates/pdb.yaml`:
- Conditional creation based on podDisruptionBudget.enabled
- Configurable minAvailable or maxUnavailable
- Selector using chart labels

### Step 11: NetworkPolicy Template

The NetworkPolicy template is defined in `helm-charts/app-chart/templates/networkpolicy.yaml`:
- Conditional creation based on networkPolicy.enabled
- Configurable ingress and egress rules
- Pod selector using chart labels

### Step 12: Installation Notes

The installation notes template is defined in `helm-charts/app-chart/templates/NOTES.txt`:
- Post-installation instructions
- Service-specific access commands
- Security context information
- Autoscaling and PDB status

### Step 13: Helm Ignore File

The Helm ignore file is defined in `helm-charts/app-chart/.helmignore`:
- Excludes development files from chart packages
- Standard patterns for Git, IDE, and temporary files

### Step 14: Validate the Helm Chart

Validate the Helm chart using the provided script:

```bash
./scripts/validate-chart.sh helm-charts/app-chart helm-charts/app-chart/values/dev.yaml
```

Or validate manually:

```bash
# Lint the chart
helm lint helm-charts/app-chart

# Validate with development values
helm lint helm-charts/app-chart -f helm-charts/app-chart/values/dev.yaml

# Validate with production values
helm lint helm-charts/app-chart -f helm-charts/app-chart/values/prod.yaml

# Dry run to see rendered templates
helm install test-dev helm-charts/app-chart \
  -f helm-charts/app-chart/values/dev.yaml \
  --dry-run --debug -n development

# Template and validate with kubeconform
helm template test-dev helm-charts/app-chart \
  -f helm-charts/app-chart/values/dev.yaml \
  -n development | kubeconform -strict -
```

Expected output: No errors, all validations pass.

### Step 15: Validate with Schema

Helm 3 automatically validates values against the schema during installation. Test it manually:

```bash
# This should succeed with valid values
helm lint helm-charts/app-chart -f helm-charts/app-chart/values/dev.yaml

# Test with invalid values (should fail)
echo "replicaCount: -1" > /tmp/invalid.yaml
helm lint helm-charts/app-chart -f /tmp/invalid.yaml
# Expected: Error - replicaCount must be >= 0
```

## Phase 3: GitOps Infrastructure Setup

### Prerequisites: GitHub Repository Setup

This project assumes you're working within the `DEVOPS_PROJECTS` mono-repository structure.

**One-time setup (from repository root):**

```bash
# Navigate to repository root
cd DEVOPS_PROJECTS

# Check if already initialized
if [ -d ".git" ]; then
  echo "Git repository already initialized"
  git status
else
  echo "Initializing new Git repository"
  git init
fi

# Add all project files
git add .
git commit -m "Initial commit: EKS cluster and Helm/GitOps configurations"

# Create GitHub repository
# Go to https://github.com/new
# Repository name: DEVOPS_PROJECTS (or your preference)
# Make it Public (simplifies ArgoCD access - no authentication needed)
# Do not initialize with README

# Add remote and push
git remote add origin https://github.com/YOUR_USERNAME/DEVOPS_PROJECTS.git
git branch -M main
git push -u origin main
```

**Verify repository structure in GitHub:**
```
DEVOPS_PROJECTS/
├── 01-EKS-CLUSTER/
├── 02-HELM-GITOPS/
│   ├── gitops-configs/
│   ├── gitops-repo/        # ArgoCD watches this path
│   │   ├── helm-charts/
│   │   └── applications/
│   ├── helm-charts/
│   ├── namespaces/
│   └── scripts/
└── 03-CICD-APP-DEPLOYMENT/
```

**Important:** ArgoCD will be configured to watch `02-HELM-GITOPS/gitops-repo/helm-charts/app-chart` within your mono-repo.

### Configure Environment from Project 1

Pull configuration values from Project 1 to use throughout Project 2:

```bash
# Navigate to Project 1 terraform directory
cd ../01-EKS-CLUSTER/terraform

# Export Project 1 outputs as environment variables
export CLUSTER_NAME=$(terraform output -raw cluster_name)
export AWS_REGION=$(terraform output -raw region)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export EXTERNAL_SECRETS_ROLE_ARN=$(terraform output -raw external_secrets_role_arn)
export DEV_SECRET_NAME=$(terraform output -raw dev_secret_name)
export PROD_SECRET_NAME=$(terraform output -raw prod_secret_name)

# Return to Project 2
cd ../../02-HELM-GITOPS

# Verify values
echo "Cluster Configuration:"
echo "  Cluster: ${CLUSTER_NAME}"
echo "  Region: ${AWS_REGION}"
echo "  Account: ${AWS_ACCOUNT_ID}"
echo ""
echo "Secrets Manager Configuration:"
echo "  IRSA Role: ${EXTERNAL_SECRETS_ROLE_ARN}"
echo "  Dev Secret: ${DEV_SECRET_NAME}"
echo "  Prod Secret: ${PROD_SECRET_NAME}"

# Save for later use
cat > .env << EOF
export CLUSTER_NAME="${CLUSTER_NAME}"
export AWS_REGION="${AWS_REGION}"
export AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID}"
export GITHUB_USERNAME="your-github-username"  # Update this
export EXTERNAL_SECRETS_ROLE_ARN="${EXTERNAL_SECRETS_ROLE_ARN}"
export DEV_SECRET_NAME="${DEV_SECRET_NAME}"
export PROD_SECRET_NAME="${PROD_SECRET_NAME}"
EOF

echo ""
echo "Environment variables saved to .env file"
echo "Source this file in new terminals: source .env"
```

Now we'll set up ArgoCD for GitOps-based deployments.

### Step 1: Install ArgoCD

Install ArgoCD **in your EKS cluster** using Helm:

```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD in the EKS cluster (creates argocd namespace)
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --values gitops-configs/argocd/values.yaml \
  --wait

# Get initial admin password from the EKS cluster
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

**Save the password** - you'll need it to log in.

**Note**: ArgoCD is now running **inside your EKS cluster** in the `argocd` namespace. The next step shows how to access it from your local machine.

### Step 2: Access ArgoCD UI

Since ArgoCD is running **inside your EKS cluster**, we'll use port-forwarding to access it from your local machine:

```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

**Access ArgoCD:**
- URL: `http://localhost:8080`
- Username: `admin`
- Password: (from previous command)

**Note**: Keep the port-forward command running in your terminal. You can stop it with `Ctrl+C` when you're done.

### Step 3: Install ArgoCD CLI (Optional but Recommended)

**Linux**:
```bash
curl -sSL -o /tmp/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /tmp/argocd
sudo mv /tmp/argocd /usr/local/bin/argocd
```

**macOS**:
```bash
brew install argocd
```

**Login via CLI**:
```bash
# Login using localhost (with port-forward running)
argocd login localhost:8080 --username admin --password <your-password> --insecure
```

### Step 4: Git Repository Structure

The GitOps repository structure has been created in `gitops-repo/` directory:
- `gitops-repo/helm-charts/` - For Helm chart source code
- `gitops-repo/applications/` - For ArgoCD Application manifests

In a production environment, this would be a Git repository that ArgoCD monitors for changes.

### Step 5: Configure ArgoCD Application for Development

The ArgoCD Application manifest is already configured at:
`gitops-configs/argocd/applications/app-dev.yaml`

**Update it with your GitHub username:**

```bash
# Replace YOUR_USERNAME with your actual GitHub username
export GITHUB_USERNAME="your-github-username"

# Update the application manifest
sed -i "s|YOUR_USERNAME|${GITHUB_USERNAME}|g" \
  gitops-configs/argocd/applications/app-dev.yaml

# Verify the change
grep "repoURL" gitops-configs/argocd/applications/app-dev.yaml
```

Expected output:
```yaml
repoURL: https://github.com/your-github-username/DEVOPS_PROJECTS.git
```

**Apply the ArgoCD Application:**

```bash
kubectl apply -f gitops-configs/argocd/applications/app-dev.yaml
```

**Note**: If you see ArgoCD sync errors, ensure you've pushed the `gitops-repo/` directory to GitHub:
```bash
git add gitops-repo/
git commit -m "Add gitops-repo structure"
git push
```

### Step 6: Configure ArgoCD Application for Production

Update production application with your GitHub username:

```bash
# Update the application manifest
sed -i "s|YOUR_USERNAME|${GITHUB_USERNAME}|g" \
  gitops-configs/argocd/applications/app-prod.yaml

# Verify the change
grep "repoURL" gitops-configs/argocd/applications/app-prod.yaml
```

**Apply the ArgoCD Application:**

```bash
kubectl apply -f gitops-configs/argocd/applications/app-prod.yaml
```

**Note**: If you see ArgoCD sync errors, ensure you've pushed the `gitops-repo/` directory to GitHub:
```bash
git add gitops-repo/
git commit -m "Add gitops-repo structure"
git push
```

### Step 7: Verify GitOps Synchronization

Check that ArgoCD has picked up the applications:

```bash
# Check application status
kubectl get applications -n argocd

# Get detailed status (if ArgoCD CLI installed)
argocd app list

# Watch sync progress
argocd app get app-dev
argocd app get app-prod
```

Expected output shows "Synced" and "Healthy" status.

**View in ArgoCD UI:**
```bash
# Port forward to ArgoCD UI (if not already running)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open https://localhost:8080 and verify both applications are synced.

### Step 8: Test the GitOps Workflow

Make a change and watch ArgoCD automatically sync it:

```bash
# Navigate to the gitops-repo helm chart
cd 02-HELM-GITOPS/gitops-repo/helm-charts/app-chart

# Make a change to development values
sed -i 's/replicaCount: 1/replicaCount: 2/' values/dev.yaml

# Commit and push the change
git add values/dev.yaml
git commit -m "Scale dev environment to 2 replicas"
git push

# Watch ArgoCD detect and sync the change (may take up to 3 minutes)
watch kubectl get pods -n development

# Or force immediate sync
argocd app sync app-dev
```

You should see the deployment scale to 2 replicas automatically. This demonstrates the GitOps workflow: Git is the source of truth, and ArgoCD ensures the cluster matches Git state.

### Step 9: Verify Deployments

```bash
# Check development deployment
kubectl get all -n development

# Check production deployment
kubectl get all -n production

# Check pod security contexts
kubectl get pod -n development -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'

kubectl get pod -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext}{"\n"}{end}'
```

## Phase 4: External Secret Management

**Prerequisites**: AWS Secrets Manager resources were provisioned in Project 1 and are ready to use.

**What we'll do in this phase**:
1. Install External Secrets Operator in Kubernetes
2. Configure the operator to use the IAM role from Project 1
3. Create SecretStores that connect to AWS Secrets Manager
4. Create ExternalSecrets that sync secrets into Kubernetes

**Cost Note**: The AWS Secrets Manager secrets created in Project 1 cost ~$0.80/month ($0.40 per secret).

### Step 1: Verify AWS Secrets Exist

Before proceeding, verify the secrets were created in Project 1:

```bash
# Source environment variables if not already done
source .env

# List secrets
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `app/config`)].Name'

# Expected output:
# [
#     "dev/app/config",
#     "prod/app/config"
# ]

# Verify you can read the dev secret
aws secretsmanager get-secret-value --secret-id ${DEV_SECRET_NAME} --query 'SecretString' --output text
```

If secrets don't exist, return to Project 1 and manually populate them with real values using the AWS CLI.

### Step 2: Install External Secrets Operator

Install External Secrets Operator using Helm:

```bash
# Add External Secrets Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Install External Secrets Operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n monitoring \
  --create-namespace \
  --set installCRDs=true \
  --wait

# Verify installation
kubectl get pods -n monitoring -l app.kubernetes.io/name=external-secrets
```

**Expected output**:
```
NAME                                  READY   STATUS    RESTARTS   AGE
external-secrets-6f9c8d5b7d-xxxxx    1/1     Running   0          30s
external-secrets-cert-controller-... 1/1     Running   0          30s
external-secrets-webhook-...         1/1     Running   0          30s
```

### Step 3: Configure IRSA for External Secrets Operator

Annotate the service account with the IAM role ARN from Project 1:

```bash
# Ensure environment variables are loaded
source .env

# Annotate the service account with the IAM role
kubectl annotate serviceaccount external-secrets \
  -n monitoring \
  eks.amazonaws.com/role-arn=${EXTERNAL_SECRETS_ROLE_ARN} \
  --overwrite

# Verify the annotation
kubectl get sa external-secrets -n monitoring -o yaml | grep eks.amazonaws.com/role-arn

# Expected output:
#   eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/eks-cluster-external-secrets

# Restart the operator to pick up the annotation
kubectl rollout restart deployment external-secrets -n monitoring
kubectl rollout restart deployment external-secrets-cert-controller -n monitoring
kubectl rollout restart deployment external-secrets-webhook -n monitoring

# Wait for rollout to complete
kubectl rollout status deployment external-secrets -n monitoring
```

### Step 4: Create SecretStore for Development

Apply the development SecretStore configuration:

```bash
kubectl apply -f gitops-configs/external-secrets/secretstore-dev.yaml
```

**What this creates**:
- A SecretStore that connects to AWS Secrets Manager
- Uses the IAM role (IRSA) for authentication
- Scoped to the development namespace
- Configured for the AWS region from Project 1

**Verify the SecretStore**:
```bash
kubectl get secretstore -n development

# Check status
kubectl describe secretstore aws-secrets-manager -n development
```

Expected status: `Valid`

### Step 5: Create SecretStore for Production

Apply the production SecretStore configuration:

```bash
kubectl apply -f gitops-configs/external-secrets/secretstore-prod.yaml
```

**Verify the SecretStore**:
```bash
kubectl get secretstore -n production

# Check status
kubectl describe secretstore aws-secrets-manager -n production
```

Expected status: `Valid`

### Step 6: Create ExternalSecret for Development

Apply the development ExternalSecret configuration:

```bash
kubectl apply -f gitops-configs/external-secrets/externalsecret-dev.yaml
```

**What this creates**:
- An ExternalSecret that references the SecretStore
- Syncs the `dev/app/config` secret from AWS Secrets Manager
- Creates a Kubernetes secret named `app-config` in the development namespace
- Refreshes every hour automatically

**Verify synchronization**:
```bash
# Check ExternalSecret status
kubectl get externalsecret app-config -n development

# Should show SecretSynced status after a few seconds
kubectl describe externalsecret app-config -n development

# Verify the Kubernetes secret was created
kubectl get secret app-config -n development

# View the secret keys (values are base64 encoded)
kubectl get secret app-config -n development -o jsonpath='{.data}' | jq
```

### Step 7: Create ExternalSecret for Production

Apply the production ExternalSecret configuration:

```bash
kubectl apply -f gitops-configs/external-secrets/externalsecret-prod.yaml
```

**Verify synchronization**:
```bash
# Check ExternalSecret status
kubectl get externalsecret app-config -n production

# Verify the Kubernetes secret was created
kubectl get secret app-config -n production

# View the secret keys
kubectl get secret app-config -n production -o jsonpath='{.data}' | jq
```

### Step 8: Verify External Secrets Setup (Empty Secrets)

Since no secrets have been populated yet, verify that the External Secrets infrastructure is properly configured:

```bash
# Check ExternalSecret status (will show error since secrets are empty)
kubectl get externalsecret app-config -n development
# Expected: SecretSyncedError or similar

kubectl get externalsecret app-config -n production
# Expected: SecretSyncedError or similar

# Check the error details
kubectl describe externalsecret app-config -n development
# Should show error about secret not found or empty

# Verify SecretStores are valid
kubectl get secretstore aws-secrets-manager -n development
kubectl get secretstore aws-secrets-manager -n production
# Expected: Valid status
```

**Note**: The ExternalSecrets will show error status because the AWS Secrets Manager secrets are empty. This is expected behavior. The secrets will be populated with real values when applications are deployed in Project 3, and the External Secrets Operator will automatically detect the change and sync them to Kubernetes.

### Step 9: Verify Complete Setup

Run a comprehensive verification:

```bash
# Check all External Secrets Operator resources
echo "=== External Secrets Operator Pods ==="
kubectl get pods -n monitoring -l app.kubernetes.io/name=external-secrets

echo ""
echo "=== SecretStores ==="
kubectl get secretstore -A

echo ""
echo "=== ExternalSecrets ==="
kubectl get externalsecret -A

echo ""
echo "=== Synced Kubernetes Secrets ==="
kubectl get secret app-config -n development
kubectl get secret app-config -n production

echo ""
echo "=== IRSA Configuration ==="
kubectl get sa external-secrets -n monitoring -o yaml | grep eks.amazonaws.com/role-arn
```

All resources should show healthy/synced status.

### Phase 4 Verification Checklist

- [ ] External Secrets Operator installed and running
- [ ] Service account annotated with IAM role ARN from Project 1
- [ ] SecretStores created in development and production namespaces
- [ ] SecretStores show "Valid" status
- [ ] ExternalSecrets created in both namespaces
- [ ] ExternalSecrets show "SecretSyncedError" status (expected with empty secrets - will be populated in Project 3)
- [ ] Infrastructure ready for secret population in Project 3

If all checks pass, External Secrets integration is complete!

## Phase 5: Deployment Automation

### Step 1: Setup Scripts

Make all scripts executable:
```bash
chmod +x scripts/*.sh
```

Verify scripts are executable:
```bash
ls -l scripts/
```

### Step 2: Validation Script

The chart validation script is defined in `scripts/validate-chart.sh`:
- Validates Helm charts with linting
- Uses kubeconform for Kubernetes manifest validation
- Supports custom values files

Run the validation script:

```bash
./scripts/validate-chart.sh helm-charts/app-chart helm-charts/app-chart/values/dev.yaml
```

### Step 3: Deployment Script

The environment deployment script is defined in `scripts/deploy-environment.sh`:
- Supports dev and prod environments
- Validates charts before deployment
- Uses atomic deployments with rollback on failure
- Shows deployment status and pod information

Run the deployment script:

```bash
./scripts/deploy-environment.sh dev
./scripts/deploy-environment.sh prod
```

### Step 4: Rollback Script

The rollback script is defined in `scripts/rollback.sh`:
- Supports dev and prod environments
- Shows release history before rollback
- Can rollback to specific revision or previous revision
- Displays new deployment status after rollback

Run the rollback script:

```bash
./scripts/rollback.sh dev
./scripts/rollback.sh prod
```

### Step 5: Test the Scripts

Test the deployment automation scripts:

```bash
# Validate development configuration
./scripts/validate-chart.sh helm-charts/app-chart helm-charts/app-chart/values/dev.yaml

# Validate production configuration
./scripts/validate-chart.sh helm-charts/app-chart helm-charts/app-chart/values/prod.yaml

# If validation passes, scripts are working correctly
```

## Verification

### Step 1: Verify Namespaces

```bash
# Check all namespaces exist
kubectl get namespaces development production monitoring logging

# Verify Pod Security Standards labels
kubectl get namespace development -o yaml | grep pod-security
kubectl get namespace production -o yaml | grep pod-security

# Check resource quotas
kubectl describe resourcequota -n development
kubectl describe resourcequota -n production
```

### Step 2: Verify Helm Deployments

```bash
# List Helm releases
helm list -A

# Check development deployment
helm status app-dev -n development
kubectl get all -n development

# Check production deployment
helm status app-prod -n production
kubectl get all -n production
```

### Step 2.5: Test Resource Quota Impact

**Understanding Resource Quotas**:

Resource quotas prevent runaway resource consumption. Test what happens when you hit the limits:

```bash
# Check current quota usage
kubectl describe resourcequota -n development

# Try to exceed the quota (this will fail)
kubectl run test-quota --image=nginx -n development --requests=cpu=100 --limits=cpu=100

# Expected error: "exceeded quota: dev-resource-quota, requested: requests.cpu=100, used: requests.cpu=0.1, limited: requests.cpu=10"

# Check quota usage after the failed attempt
kubectl describe resourcequota -n development

# Clean up the failed pod
kubectl delete pod test-quota -n development --ignore-not-found
```

This demonstrates that resource quotas are working correctly and preventing resource exhaustion.

### Step 3: Verify Security Contexts

```bash
# Check pod security contexts in development
kubectl get pod -n development -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsNonRoot}{"\t"}{.spec.securityContext.runAsUser}{"\n"}{end}'

# Check pod security contexts in production
kubectl get pod -n production -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsNonRoot}{"\t"}{.spec.securityContext.runAsUser}{"\n"}{end}'

# Verify read-only root filesystem
kubectl get pod -n production -o jsonpath='{range .items[*].spec.containers[*]}{.name}{"\t"}{.securityContext.readOnlyRootFilesystem}{"\n"}{end}'
```

### Step 4: Verify Network Policies

```bash
# Check network policies
kubectl get networkpolicy -n development
kubectl get networkpolicy -n production

# Describe network policies
kubectl describe networkpolicy -n development
kubectl describe networkpolicy -n production
```

### Step 5: Verify ArgoCD

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# If you created ArgoCD applications, check their status
kubectl get applications -n argocd
```

### Step 6: Verify External Secrets Operator

```bash
# Check ESO pods
kubectl get pods -n monitoring -l app.kubernetes.io/name=external-secrets

# Check SecretStores
kubectl get secretstore -n development
kubectl get secretstore -n production

# Check ExternalSecrets
kubectl get externalsecret -n development
kubectl get externalsecret -n production

# Verify secrets were created
kubectl get secret app-config -n development
kubectl get secret app-config -n production
```

### Step 7: Test Network Policies

Test that network policies are enforcing isolation:

```bash
# This should succeed (same-namespace communication)
kubectl run test-allowed -n development --image=busybox:1.28 --rm -it --restart=Never -- \
  wget -O- http://app-dev-app-chart:8080 --timeout=5

# This should timeout (cross-namespace blocked)
kubectl run test-blocked -n development --image=busybox:1.28 --rm -it --restart=Never -- \
  wget -O- http://app-prod-app-chart.production:8080 --timeout=5
```

Expected results:
- First command should succeed (same namespace communication allowed)
- Second command should timeout (cross-namespace communication blocked)

### Step 8: Test Application Access

**Development (port-forward)**:
```bash
# Get pod name
POD_NAME=$(kubectl get pods -n development -l app.kubernetes.io/instance=app-dev -o jsonpath='{.items[0].metadata.name}')

# Port forward
kubectl port-forward -n development $POD_NAME 8080:8080

# In another terminal or browser, access:
# http://localhost:8080
```

**Production (if LoadBalancer)**:
```bash
# Get LoadBalancer IP
kubectl get svc -n production app-prod-app-chart

# Access via the EXTERNAL-IP shown (may take a few minutes to provision)
```

### Verification Checklist

- [ ] All four namespaces created with proper PSS labels
- [ ] Resource quotas and limit ranges active
- [ ] Network policies configured and tested
- [ ] Helm charts deployed to development and production
- [ ] Pods running with non-root users (UID 65534)
- [ ] Read-only root filesystems enforced
- [ ] ArgoCD installed and accessible
- [ ] External Secrets Operator installed
- [ ] SecretStores configured
- [ ] Secrets synchronized from AWS Secrets Manager
- [ ] Validation scripts working
- [ ] Applications accessible

## Final Integration Test

This section demonstrates the complete workflow and validates that all components work together properly.

### Step 1: Test GitOps Workflow

Make a change to the application and watch it deploy automatically:

```bash
# Navigate to the gitops-repo helm chart
cd 02-HELM-GITOPS/gitops-repo/helm-charts/app-chart

# Make a visible change to development values
sed -i 's/replicaCount: 1/replicaCount: 3/' values/dev.yaml

# Commit and push the change
git add values/dev.yaml
git commit -m "Scale dev environment to 3 replicas for testing"
git push

# Watch ArgoCD detect and sync the change
watch kubectl get pods -n development

# Verify the change was applied
kubectl get deployment -n development app-dev-app-chart -o jsonpath='{.spec.replicas}'
# Expected output: 3
```

### Step 2: Test Automatic Rollback

Intentionally break the deployment to test automatic rollback:

```bash
# Make an invalid change that will cause deployment failure
sed -i 's/image: nginx:alpine/image: nonexistent:invalid/' values/dev.yaml

# Commit and push the broken change
git add values/dev.yaml
git commit -m "Test rollback with invalid image"
git push

# Watch the deployment fail and rollback
watch kubectl get pods -n development

# Check deployment status
kubectl get deployment -n development app-dev-app-chart

# Verify rollback occurred (should show previous working revision)
helm history app-dev -n development
```

### Step 3: Restore Working State

Fix the deployment by reverting to a working configuration:

```bash
# Revert to working image
sed -i 's/image: nonexistent:invalid/image: nginx:alpine/' values/dev.yaml

# Also revert replica count to original
sed -i 's/replicaCount: 3/replicaCount: 1/' values/dev.yaml

# Commit and push the fix
git add values/dev.yaml
git commit -m "Restore working configuration"
git push

# Verify deployment is healthy again
kubectl get pods -n development
kubectl get deployment -n development app-dev-app-chart
```

### Step 4: Test Manual Rollback

Test the manual rollback script:

```bash
# Use the rollback script
./scripts/rollback.sh dev

# Follow the prompts to rollback to a previous revision
# Verify the rollback was successful
kubectl get pods -n development
```

### Integration Test Checklist

- [ ] GitOps workflow: Changes in Git automatically sync to cluster
- [ ] Automatic rollback: Failed deployments rollback automatically
- [ ] Manual rollback: Rollback script works correctly
- [ ] Network policies: Isolation between namespaces enforced
- [ ] External Secrets: Secrets synchronized from AWS Secrets Manager
- [ ] Resource quotas: Limits prevent resource exhaustion
- [ ] Security contexts: Pods run with non-root users and read-only filesystems

## Troubleshooting

### Issue 1: Pod Fails with "container has runAsNonRoot and image will run as root"

**Cause**: The container image tries to run as root, but PSS policy prevents it.

**Solution**:
```bash
# The nginx:alpine image needs to be configured properly
# For now, check that your values specify runAsUser
kubectl get deployment -n development app-dev-app-chart -o yaml | grep runAsUser

# Ensure runAsUser: 65534 is set in pod and container security contexts
```

**Permanent fix**: In Project 3, we'll build custom images that run as non-root by default.

### Issue 2: ReadinessProbe Failing

**Cause**: Nginx on port 8080 may not be properly configured, or the image is expecting root privileges.

**Solution**:
```bash
# Check pod logs
kubectl logs -n development <pod-name>

# Check probe configuration
kubectl get deployment -n development app-dev-app-chart -o yaml | grep -A 10 readinessProbe

# For nginx:alpine, you may need to adjust the port or disable probes temporarily
```

**Temporary workaround** - update the values files to use standard nginx port (80) instead of 8080, then upgrade:

```bash
helm upgrade app-dev helm-charts/app-chart \
  -f helm-charts/app-chart/values/dev.yaml \
  -n development
```

### Issue 3: Permission Denied for /tmp or /var/run

**Cause**: Read-only root filesystem prevents writing to standard locations.

**Solution**: Our chart already includes emptyDir mounts for /tmp and /var/run:

```bash
# Verify mounts exist
kubectl get deployment -n development app-dev-app-chart -o yaml | grep -A 10 volumeMounts

# If not present, they're in values.yaml and should be rendered
```

### Issue 4: External Secrets Not Syncing

**Symptoms**:
```bash
kubectl get externalsecret -n development
# Shows status: SecretSyncedError
```

**Solution**:
```bash
# Check ESO logs
kubectl logs -n monitoring -l app.kubernetes.io/name=external-secrets

# Verify IAM permissions
aws sts get-caller-identity

# Check SecretStore status
kubectl describe secretstore -n development aws-secrets-manager

# Verify secret exists in AWS
aws secretsmanager get-secret-value --secret-id dev/app/config

# Check service account annotation
kubectl get sa external-secrets -n monitoring -o yaml | grep eks.amazonaws.com/role-arn
```

### Issue 5: Network Policy Blocks Required Traffic

**Symptoms**: Pods can't communicate or resolve DNS.

**Solution**:
```bash
# Check network policies
kubectl get networkpolicy -n production

# Temporarily disable to test
kubectl delete networkpolicy -n production prod-default-deny

# If this fixes it, update network policy to allow required traffic
# Then reapply the correct policy
```

### Issue 6: Resource Quota Exceeded

**Symptoms**:
```bash
Error from server (Forbidden): pods "app-dev-xxx" is forbidden: 
exceeded quota: dev-resource-quota, requested: requests.cpu=1, 
used: requests.cpu=9.5, limited: requests.cpu=10
```

**Solution**:
```bash
# Check current usage
kubectl describe resourcequota -n development

# Either scale down existing deployments or increase quota
kubectl edit resourcequota dev-resource-quota -n development

# Or reduce resource requests in your Helm values
```

### Issue 7: Helm Deployment Fails Atomic Rollback

**Symptoms**: Deployment fails and Helm automatically rolls back.

**Solution**:
```bash
# Check rollback status
helm history app-dev -n development

# Review logs from failed deployment
kubectl logs -n development <pod-name> --previous

# Fix the issue in values or chart, then retry deployment
```

## Cleanup

### Step 1: Delete Helm Releases

```bash
# Delete development deployment
helm uninstall app-dev -n development

# Delete production deployment
helm uninstall app-prod -n production
```

### Step 2: Delete External Secrets Resources

```bash
# Delete ExternalSecrets
kubectl delete externalsecret --all -n development
kubectl delete externalsecret --all -n production

# Delete SecretStores
kubectl delete secretstore --all -n development
kubectl delete secretstore --all -n production

# Uninstall External Secrets Operator
helm uninstall external-secrets -n monitoring
```

**Note**: AWS Secrets Manager resources (secrets, IAM policy, IAM role) are managed by Project 1's Terraform and will be destroyed when you run `terraform destroy` in Project 1.

### Step 3: Delete ArgoCD

```bash
# Delete ArgoCD applications (if created)
kubectl delete applications --all -n argocd

# Delete ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete namespace
kubectl delete namespace argocd
```

### Step 4: Delete Namespaces

```bash
# Delete application namespaces (this deletes everything in them)
kubectl delete namespace development
kubectl delete namespace production
kubectl delete namespace logging

# Keep monitoring namespace if needed for Project 4
# kubectl delete namespace monitoring
```

### Verification

```bash
# Verify all resources cleaned up
kubectl get all -A
kubectl get namespaces
helm list -A
```

## Cost Considerations

### Additional Costs from Project 2

| Resource | Cost | Notes |
|----------|------|-------|
| **ArgoCD** | $0 | Uses existing cluster resources |
| **ArgoCD LoadBalancer** | ~$16/month | Network Load Balancer for external access |
| **External Secrets Operator** | $0 | Uses existing cluster resources |
| **AWS Secrets Manager** | ~$0.40/secret/month | $0.40 per secret + $0.05 per 10,000 API calls |
| **Additional CPU/Memory** | ~$5-10/month | Depends on workload |

### Cost Breakdown

**ArgoCD Resource Usage**:
- CPU: ~200m per component × 4 components = 800m
- Memory: ~256Mi per component × 4 components = 1Gi
- Estimated cost: ~$5/month (included in node costs)

**External Secrets Operator**:
- CPU: ~100m
- Memory: ~128Mi
- Estimated cost: ~$1/month (included in node costs)

**AWS Secrets Manager** (provisioned in Project 1):
- 2 secrets × $0.40 = $0.80/month
- API calls: ~$0.05/month (assuming 10,000 calls)
- Total: ~$0.85/month
- Note: Secrets are destroyed when Project 1 is destroyed via `terraform destroy`

**Total Additional Monthly Cost**: ~$22-27/month on top of Project 1

### Cost Optimization Tips

1. **Use fewer secrets**: Consolidate related secrets into single AWS Secrets Manager entries
2. **Increase refresh intervals**: Default 1h is good; avoid frequent refreshes
3. **Resource limits**: Set appropriate CPU/memory limits for all workloads
4. **Development environment**: Scale down or delete when not in use

## Security Best Practices

### Pod Security Standards

**What We Implemented**:
- ✅ Development: Baseline enforcement with Restricted warnings
- ✅ Production: Restricted enforcement (most secure)
- ✅ Monitoring/Logging: Baseline (for observability tools)

**Restricted Profile Requirements** (Production):
- Non-root user execution
- No privilege escalation
- Read-only root filesystem
- Seccomp profile enforcement
- Dropped Linux capabilities

### Secret Management

**Best Practices**:
- ✅ Never store secrets in Git repositories
- ✅ Use External Secrets Operator for centralized management
- ✅ Rotate secrets regularly via AWS Secrets Manager
- ✅ Use IRSA for AWS authentication (no static credentials)
- ✅ Namespace-scoped SecretStores for isolation

### Network Security

**Implemented Controls**:
- ✅ Default-deny network policies in production
- ✅ Explicit allow rules for required traffic
- ✅ DNS access to kube-system namespace
- ✅ Same-namespace communication allowed

**Production Network Policy** ensures:
- No ingress traffic by default
- Only explicitly allowed egress
- DNS resolution permitted
- Namespace isolation

### RBAC and Access Control

**Service Accounts**:
- Each application has its own service account
- Minimal permissions granted
- IRSA for AWS service access

**Recommendations for Production**:
- Create namespace-specific admin roles
- Use separate service accounts for CI/CD
- Implement least-privilege access
- Audit access logs regularly

### GitOps Security

**Best Practices**:
- ✅ Git as single source of truth
- ✅ Automated syncing for development
- ✅ Manual sync for production (approval required)
- ✅ Drift detection and correction
- ✅ Audit trail via Git history

### Compliance Checklist

- [ ] All production workloads pass Restricted PSS profile
- [ ] Secrets managed via External Secrets Operator
- [ ] Network policies enforce least-privilege communication
- [ ] Resource quotas prevent resource exhaustion
- [ ] Service accounts use IRSA (no static credentials)
- [ ] Git repository requires signed commits
- [ ] Production deployments require approval
- [ ] All changes are auditable via Git history

## Next Steps

**Congratulations!** 🎉 You now have a secure, production-ready environment management system.

### What You Accomplished

- ✅ Created four namespaces with Pod Security Standards enforcement
- ✅ Built modern Helm charts with security-compliant templates
- ✅ Set up ArgoCD for GitOps workflows
- ✅ Configured External Secrets Operator for secure secret management
- ✅ Implemented resource quotas and network policies
- ✅ Established automated deployment and rollback procedures

### Project 3 Preview

In the next project, you'll:
- Build a sample application with non-root user configuration
- Create container images using Packer
- Set up CodeBuild for CI/CD pipeline
- Push images to Amazon ECR
- Deploy the application using your Helm charts
- Implement automated testing and deployment

**Ready to continue?** → Proceed to **Project 3 - Sample Application Deployment with Packer and CodeBuild**

### Additional Learning Resources

- **Pod Security Standards**: https://kubernetes.io/docs/concepts/security/pod-security-standards/
- **Helm Best Practices**: https://helm.sh/docs/chart_best_practices/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/
- **External Secrets Operator**: https://external-secrets.io/
- **Network Policies**: https://kubernetes.io/docs/concepts/services-networking/network-policies/

---

## Appendix

### Helm Commands Reference

```bash
# List all releases across namespaces
helm list -A

# Get release history
helm history <release-name> -n <namespace>

# Rollback to previous revision
helm rollback <release-name> -n <namespace>

# Rollback to specific revision
helm rollback <release-name> <revision> -n <namespace>

# Show values for a release
helm get values <release-name> -n <namespace>

# Show all rendered manifests
helm get manifest <release-name> -n <namespace>

# Upgrade release
helm upgrade <release-name> <chart> -f <values> -n <namespace>

# Upgrade with atomic (auto-rollback on failure)
helm upgrade <release-name> <chart> -f <values> -n <namespace> --atomic --timeout 5m

# Dry run
helm install <release-name> <chart> -f <values> -n <namespace> --dry-run --debug

# Template (render without installing)
helm template <release-name> <chart> -f <values> -n <namespace>

# Uninstall release
helm uninstall <release-name> -n <namespace>
```

### kubectl Security Context Commands

```bash
# Check pod security context
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.securityContext}'

# Check container security context
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[0].securityContext}'

# Check all security contexts in namespace
kubectl get pods -n <namespace> -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsUser}{"\n"}{end}'

# Verify read-only root filesystem
kubectl get pods -n <namespace> -o jsonpath='{range .items[*].spec.containers[*]}{.name}{"\t"}{.securityContext.readOnlyRootFilesystem}{"\n"}{end}'

# Check capabilities
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.containers[0].securityContext.capabilities}'
```

### Network Policy Testing

```bash
# Test DNS resolution
kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -n <namespace> -- nslookup kubernetes.default

# Test connectivity to pod in same namespace
kubectl run test-connect --image=busybox:1.28 --rm -it --restart=Never -n <namespace> -- wget -O- http://<service-name>

# Test connectivity to pod in different namespace (should fail with default-deny)
kubectl run test-connect --image=busybox:1.28 --rm -it --restart=Never -n production -- wget -O- http://<service>.<other-namespace>
```

### ArgoCD CLI Commands

```bash
# List applications
argocd app list

# Get application details
argocd app get <app-name>

# Sync application
argocd app sync <app-name>

# Rollback application
argocd app rollback <app-name>

# Set application to auto-sync
argocd app set <app-name> --sync-policy automated

# Disable auto-sync
argocd app set <app-name> --sync-policy none

# View application history
argocd app history <app-name>

# Diff between Git and cluster
argocd app diff <app-name>
```

### External Secrets Operator Commands

```bash
# Check ESO status
kubectl get externalsecrets -A
kubectl get secretstores -A

# Describe ExternalSecret
kubectl describe externalsecret <name> -n <namespace>

# Check ESO controller logs
kubectl logs -n monitoring -l app.kubernetes.io/name=external-secrets

# Force secret refresh
kubectl annotate externalsecret <name> -n <namespace> force-sync="$(date +%s)" --overwrite

# Check synchronized secret
kubectl get secret <name> -n <namespace> -o yaml
```

---

**Document Version**: 1.0  
**Last Updated**: September 2025  
**Dependencies**: Project 1 complete  
**Next Project**: Project 3 - Sample Application Deployment with Packer and CodeBuild