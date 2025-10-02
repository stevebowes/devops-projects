# kubectl Configuration for AWS EKS Clusters

## Overview

This document explains how kubectl connects to AWS EKS clusters, the role of the `~/.kube/config` file, and the authentication mechanisms involved.

## Table of Contents

- [What is ~/.kube/config?](#what-is-kubeconfig)
- [How EKS Authentication Works](#how-eks-authentication-works)
- [The `aws eks update-kubeconfig` Command](#the-aws-eks-update-kubeconfig-command)
- [Understanding the Configuration Structure](#understanding-the-configuration-structure)
- [Authentication Flow](#authentication-flow)
- [Troubleshooting kubectl Access](#troubleshooting-kubectl-access)
- [Best Practices](#best-practices)

## What is ~/.kube/config?

The `~/.kube/config` file is kubectl's configuration file that contains:

- **Cluster information**: API server endpoints, certificate authorities
- **User authentication**: Credentials and authentication methods
- **Contexts**: Which cluster, user, and namespace to use by default
- **Current context**: The active configuration

### File Location
```bash
# Default location
~/.kube/config

# Can be overridden with KUBECONFIG environment variable
export KUBECONFIG=/path/to/your/config
```

## How EKS Authentication Works

AWS EKS uses a unique authentication model:

1. **EKS Control Plane**: Managed by AWS, runs the Kubernetes API server
2. **Authentication**: Uses AWS IAM for authentication, not traditional kubeconfig credentials
3. **Authorization**: Uses Kubernetes RBAC (Role-Based Access Control)
4. **Token Refresh**: Tokens are automatically refreshed using AWS CLI credentials

### Key Differences from Self-Managed Kubernetes

| Aspect | Self-Managed K8s | AWS EKS |
|--------|------------------|---------|
| Authentication | Static tokens, certificates | AWS IAM + temporary tokens |
| API Server | You manage | AWS managed |
| Certificate Authority | You provide | AWS managed |
| Token Expiration | Manual renewal | Automatic refresh |

## The `aws eks update-kubeconfig` Command

### Basic Usage
```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

### What This Command Does

1. **Retrieves cluster information** from AWS EKS API
2. **Gets the cluster endpoint** (e.g., `https://xxxxx.gr7.us-east-1.eks.amazonaws.com`)
3. **Retrieves the certificate authority** (CA) data
4. **Creates or updates** the `~/.kube/config` file
5. **Sets up authentication** using AWS IAM

### Command Options

```bash
# Basic usage
aws eks update-kubeconfig --region us-east-1 --name my-cluster

# Specify a different kubeconfig file
aws eks update-kubeconfig --region us-east-1 --name my-cluster --kubeconfig ~/.kube/my-cluster-config

# Set as default context
aws eks update-kubeconfig --region us-east-1 --name my-cluster --set-context

# Force overwrite existing configuration
aws eks update-kubeconfig --region us-east-1 --name my-cluster --force
```

## Understanding the Configuration Structure

After running `aws eks update-kubeconfig`, your `~/.kube/config` file will contain something like this:

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0t...
    server: https://xxxxx.gr7.us-east-1.eks.amazonaws.com
  name: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
contexts:
- context:
    cluster: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
    user: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
  name: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
current-context: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
users:
- name: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - my-cluster
        - --region
        - us-east-1
      env:
        - name: AWS_PROFILE
          value: default
```

### Key Components Explained

#### 1. Cluster Configuration
```yaml
clusters:
- cluster:
    certificate-authority-data: <base64-encoded-ca-cert>
    server: https://xxxxx.gr7.us-east-1.eks.amazonaws.com
  name: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
```

- **server**: The EKS API server endpoint
- **certificate-authority-data**: Base64-encoded CA certificate for TLS verification
- **name**: Unique identifier for the cluster

#### 2. User Configuration
```yaml
users:
- name: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: aws
      args:
        - eks
        - get-token
        - --cluster-name
        - my-cluster
        - --region
        - us-east-1
```

- **exec**: Uses external command for authentication
- **command**: The AWS CLI command to get tokens
- **args**: Arguments passed to the AWS CLI

#### 3. Context Configuration
```yaml
contexts:
- context:
    cluster: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
    user: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
  name: arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
```

- **cluster**: References the cluster configuration
- **user**: References the user configuration
- **name**: Unique identifier for the context

## Authentication Flow

When you run a kubectl command, here's what happens:

1. **kubectl reads** `~/.kube/config`
2. **Identifies the current context** and associated cluster/user
3. **Executes the authentication command** (`aws eks get-token`)
4. **AWS CLI authenticates** using your AWS credentials
5. **EKS returns a temporary token** (valid for ~15 minutes)
6. **kubectl uses the token** to authenticate with the API server
7. **API server validates** the token and processes the request

### Token Refresh
```bash
# Tokens are automatically refreshed when they expire
# You can manually refresh by running any kubectl command
kubectl get nodes
```

## Troubleshooting kubectl Access

### Common Issues and Solutions

#### 1. "Unable to connect to the server"
```bash
# Check if cluster exists and is active
aws eks describe-cluster --name my-cluster --region us-east-1

# Reconfigure kubectl
aws eks update-kubeconfig --region us-east-1 --name my-cluster --force
```

#### 2. "You must be logged in to the server (Unauthorized)"
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify you have EKS access
aws eks list-clusters --region us-east-1

# Check if your user/role has EKS permissions
aws iam list-attached-user-policies --user-name your-username
```

#### 3. "The security token included in the request is invalid"
```bash
# Refresh AWS credentials
aws configure

# Or if using temporary credentials, get new ones
aws sts assume-role --role-arn arn:aws:iam::123456789012:role/MyRole --role-session-name test
```

#### 4. "context was not found"
```bash
# List available contexts
kubectl config get-contexts

# Switch to the correct context
kubectl config use-context arn:aws:eks:us-east-1:123456789012:cluster/my-cluster
```

### Debugging Commands

```bash
# View current configuration
kubectl config view

# View current context
kubectl config current-context

# Test cluster connectivity
kubectl cluster-info

# Check authentication
kubectl auth can-i get pods

# Verbose output for debugging
kubectl get nodes -v=6
```

## Best Practices

### 1. Use Multiple kubeconfig Files
```bash
# For different environments
export KUBECONFIG=~/.kube/dev-config:~/.kube/prod-config

# Or use kubectx/kubens for easier switching
kubectx dev-cluster
kubectx prod-cluster
```

### 2. Secure Your kubeconfig
```bash
# Set proper permissions
chmod 600 ~/.kube/config

# Don't commit kubeconfig to version control
echo "~/.kube/config" >> .gitignore
```

### 3. Use IAM Roles Instead of Users
```bash
# For EC2 instances, use IAM roles
# For local development, use IAM users with minimal permissions
```

### 4. Regular Credential Rotation
```bash
# Rotate AWS access keys regularly
# Use temporary credentials when possible
aws sts assume-role --role-arn arn:aws:iam::123456789012:role/EKSAdmin
```

### 5. Environment-Specific Configurations
```bash
# Create separate configs for different environments
aws eks update-kubeconfig --region us-east-1 --name dev-cluster --kubeconfig ~/.kube/dev-config
aws eks update-kubeconfig --region us-west-2 --name prod-cluster --kubeconfig ~/.kube/prod-config
```

## Security Considerations

### 1. Token Expiration
- EKS tokens expire after ~15 minutes
- kubectl automatically refreshes tokens
- No manual token management required

### 2. Network Security
- EKS API endpoints can be public or private
- Use private endpoints for production
- Consider VPC endpoints for cost optimization

### 3. IAM Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
```

## Common kubectl Commands for EKS

```bash
# Basic cluster information
kubectl cluster-info
kubectl get nodes
kubectl get pods -A

# Check EKS-specific resources
kubectl get nodes -o wide
kubectl describe node <node-name>

# View system pods (EKS addons)
kubectl get pods -n kube-system
kubectl get pods -n kube-system -l k8s-app=aws-node  # VPC CNI
kubectl get pods -n kube-system -l k8s-app=kube-dns  # CoreDNS

# Check cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Summary

The `aws eks update-kubeconfig` command is essential for connecting kubectl to EKS clusters. It:

1. **Retrieves cluster metadata** from AWS
2. **Configures authentication** using AWS IAM
3. **Sets up automatic token refresh**
4. **Creates a working kubeconfig** file

Understanding this process helps with troubleshooting connectivity issues and maintaining secure access to your EKS clusters.

---

**Note**: This configuration works even when worker nodes are not ready, as kubectl connects directly to the EKS control plane, not the worker nodes.
