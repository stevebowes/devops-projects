
# Getting Started with the DevOps Projects Series

## Overview

This repository contains 5 iterative DevOps projects that build a complete, production-ready Kubernetes infrastructure on AWS. Each project builds on the previous one.

**What you'll build across all 5 projects:**
1. **Project 1**: AWS EKS cluster with Terraform
2. **Project 2**: Helm charts, GitOps (ArgoCD), and External Secrets
3. **Project 3**: CI/CD pipeline with CodeBuild and Packer
4. **Project 4**: Monitoring stack (Prometheus + Grafana)
5. **Project 5**: Logging stack (OpenSearch + Fluent Bit)

## Prerequisites

Before starting any project, you need:

- **AWS Account** with admin-level permissions
- **AWS CLI** installed and configured
- **Terraform** (≥1.5.7)
- **kubectl** (≥1.31)
- **Helm** (≥3.19.0)
- **Git** installed
- **GitHub account** (free tier is fine)

## Step 1: Clone the Repository

Clone this repository to your local machine:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/DEVOPS_PROJECTS.git

# Navigate into the repository
cd DEVOPS_PROJECTS

# Verify the structure
ls -la
```

**Expected structure:**
```
DEVOPS_PROJECTS/
├── 00-GETTING-STARTED.md          # This file
├── 01-EKS-CLUSTER/                # Project 1
├── 02-HELM-GITOPS/                # Project 2
├── 03-CICD-APP-DEPLOYMENT/        # Project 3
├── 04-MONITORING-STACK/           # Project 4
├── 05-LOGGING-STACK/              # Project 5
└── README.md
```

## Step 2: Fork the Repository (Optional but Recommended)

If you want to track your changes and enable GitOps workflows in Project 2, fork the repository to your own GitHub account:

1. Go to https://github.com/YOUR_USERNAME/DEVOPS_PROJECTS
2. Click the "Fork" button in the top right
3. Clone your fork instead:

```bash
# Clone your fork
git clone https://github.com/YOUR_GITHUB_USERNAME/DEVOPS_PROJECTS.git
cd DEVOPS_PROJECTS

# Add upstream remote to pull future updates
git remote add upstream https://github.com/YOUR_USERNAME/DEVOPS_PROJECTS.git
```

## Step 3: Configure Git (If You Forked)

If you forked the repository, configure your Git identity:

```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

## Step 4: Start with Project 1

Now you're ready to begin:

```bash
# Navigate to Project 1
cd 01-EKS-CLUSTER

# Read the deployment guide
cat eks-deployment-guide.md

# Or open it in your preferred markdown viewer
```

**Important**: Complete projects in order (1 → 2 → 3 → 4 → 5) as each builds on the previous.

## Project Dependencies

```
Project 1 (EKS Cluster)
    ↓
Project 2 (Helm + GitOps) ← Requires Project 1 outputs
    ↓
Project 3 (CI/CD) ← Requires Projects 1 & 2
    ↓
Project 4 (Monitoring) ← Requires Projects 1, 2 & 3
    ↓
Project 5 (Logging) ← Requires Projects 1-4
```

## Working with Your Fork

If you forked the repository, here's the workflow:

```bash
# Make changes as you progress through projects
git add .
git commit -m "Completed Project 1: EKS deployment"
git push origin main

# Pull future updates from upstream
git fetch upstream
git merge upstream/main
```

## ArgoCD GitOps Setup (Project 2)

When you reach Project 2, ArgoCD will need to watch your GitHub repository. This is why forking is recommended:

- **If you forked**: ArgoCD will watch `https://github.com/YOUR_GITHUB_USERNAME/DEVOPS_PROJECTS.git`
- **If you didn't fork**: You'll need to use the original repo URL (read-only for you)

## Troubleshooting

**Issue**: Git authentication fails
```bash
# Configure GitHub authentication
gh auth login
# Or use SSH keys: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
```

**Issue**: Repository already exists locally
```bash
# Pull latest changes
cd DEVOPS_PROJECTS
git pull origin main
```

## Next Steps

You're ready to start! Navigate to Project 1:

```bash
cd 01-EKS-CLUSTER
open eks-deployment-guide.md  # macOS
xdg-open eks-deployment-guide.md  # Linux
```

Follow the deployment guide step-by-step. Each project includes:
- Detailed prerequisites
- Step-by-step instructions
- Complete configuration files
- Verification steps
- Troubleshooting guidance

Good luck! 🚀
```

## Update Project 2 Deployment Guide

Replace the entire "Prerequisites: GitHub Repository Setup" section with this:

```markdown
### Prerequisites: GitHub Repository Setup

**This step should already be complete** if you followed the Getting Started guide (`00-GETTING-STARTED.md`). 

**Verify your repository is ready:**

```bash
# Ensure you're in the repository root
cd DEVOPS_PROJECTS

# Verify git is initialized and you have a remote
git remote -v

# Expected output:
# origin  https://github.com/YOUR_GITHUB_USERNAME/DEVOPS_PROJECTS.git (fetch)
# origin  https://github.com/YOUR_GITHUB_USERNAME/DEVOPS_PROJECTS.git (push)

# Verify you're on the main branch
git branch --show-current

# Verify repository structure
ls -la 01-EKS-CLUSTER 02-HELM-GITOPS 03-CICD-APP-DEPLOYMENT
```

**If git is not configured**, return to the Getting Started guide and complete the repository setup before continuing with Project 2.

**Important for ArgoCD**: ArgoCD needs to monitor your GitHub repository. Ensure you:
1. Forked the repository to your own GitHub account
2. Can push changes to your fork
3. Your repository is public (or configure ArgoCD with credentials for private repos)
```

## Website Landing Page Suggestion

On your website landing page, add a prominent section:

```markdown
## Quick Start

### New to the Projects?

1. **[Download or Fork the Repository](https://github.com/YOUR_USERNAME/DEVOPS_PROJECTS)**
2. **[Read Getting Started Guide](./00-GETTING-STARTED.md)** ← Start here!
3. **Begin Project 1** → Follow deployment guides in order

### Project Guides
- [📘 Getting Started](./00-GETTING-STARTED.md) - **READ THIS FIRST**
- [📗 Project 1: EKS Cluster](./01-EKS-CLUSTER/eks-deployment-guide.md)
- [📙 Project 2: Helm & GitOps](./02-HELM-GITOPS/helm-gitops-deployment-guide.md)
- [📕 Project 3: CI/CD Pipeline](./03-CICD-APP-DEPLOYMENT/cicd-deployment-guide.md)
- [📔 Project 4: Monitoring Stack](./04-MONITORING-STACK/monitoring-deployment-guide.md)
- [📓 Project 5: Logging Stack](./05-LOGGING-STACK/logging-deployment-guide.md)
```

## Benefits of This Approach

1. **One-time setup**: Users clone once, use for all 5 projects
2. **Clear entry point**: Getting Started guide is the obvious first step
3. **Forking workflow**: Users get their own copy for GitOps
4. **No confusion**: No conflicting instructions between projects
5. **Better UX**: Clear progression from setup → Project 1 → Project 2, etc.

The key insight: repository setup is a **prerequisite for the entire series**, not specific to Project 2. Moving it to a dedicated Getting Started guide makes the workflow clearer.