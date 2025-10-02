# Project 1 - EKS Cluster Deployment

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Terraform Configuration](#terraform-configuration)
- [Deployment Instructions](#deployment-instructions)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Cost Considerations](#cost-considerations)
- [Security Best Practices](#security-best-practices)
- [Next Steps](#next-steps)

## Overview

**Project Goal**: Deploy a production-ready Amazon EKS (Elastic Kubernetes Service) cluster that serves as the foundation for subsequent DevOps projects.

**What You'll Build**:
- A fully managed Kubernetes cluster (EKS) running Kubernetes 1.32
- Custom VPC with public and private subnets across 2 availability zones
- Managed node group with 2-4 EC2 instances running Amazon Linux 2023
- Proper networking with NAT gateways and security groups
- Essential EKS addons (VPC CNI, CoreDNS, kube-proxy)

**Success Criteria**:
- ✅ EKS cluster accessible via kubectl
- ✅ Worker nodes healthy and ready
- ✅ System pods running successfully
- ✅ Infrastructure fully managed by Terraform
- ✅ Can be destroyed and recreated cleanly

**Time Estimate**: 30-40 minutes total
- Terraform apply: ~15-20 minutes
- Node group ready: ~5 minutes
- Verification: ~5 minutes

**Important Version Information**:
This guide uses **current best practices as of September 2025**:
- **Terraform AWS EKS Module**: v20.37.2 (stable, production-ready)
- **Terraform AWS VPC Module**: v5.21.0 (compatible with EKS v20.x)
- **Kubernetes Version**: 1.32 (recommended for stability)
- **Node AMI**: Amazon Linux 2023 (AL2 reaches EOL November 26, 2025)
- **Authentication**: EKS Access Entries with proper IAM role configuration
- **Minimum Requirements**: Terraform ≥1.5.7, AWS Provider >=5.95.0, <6.0.0

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                          AWS Region                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   VPC (10.0.0.0/16)                   │  │
│  │                                                        │  │
│  │  ┌──────────────────┐      ┌──────────────────┐      │  │
│  │  │  Availability    │      │  Availability    │      │  │
│  │  │    Zone 1        │      │    Zone 2        │      │  │
│  │  │                  │      │                  │      │  │
│  │  │ ┌─────────────┐  │      │ ┌─────────────┐  │      │  │
│  │  │ │   Public    │  │      │ │   Public    │  │      │  │
│  │  │ │   Subnet    │◄─┼──────┼─┤   Subnet    │  │      │  │
│  │  │ │ (10.0.0/24) │  │      │ │ (10.0.1/24) │  │      │  │
│  │  │ └──────┬──────┘  │      │ └──────┬──────┘  │      │  │
│  │  │        │ NAT GW  │      │        │ NAT GW  │      │  │
│  │  │ ┌──────▼──────┐  │      │ ┌──────▼──────┐  │      │  │
│  │  │ │   Private   │  │      │ │   Private   │  │      │  │
│  │  │ │   Subnet    │  │      │ │   Subnet    │  │      │  │
│  │  │ │ (10.0.10/24)│  │      │ │ (10.0.11/24)│  │      │  │
│  │  │ │             │  │      │ │             │  │      │  │
│  │  │ │ [EKS Nodes] │  │      │ │ [EKS Nodes] │  │      │  │
│  │  │ └─────────────┘  │      │ └─────────────┘  │      │  │
│  │  └──────────────────┘      └──────────────────┘      │  │
│  │            │                         │                │  │
│  │            └─────────┬───────────────┘                │  │
│  │                      │                                │  │
│  │              ┌───────▼────────┐                       │  │
│  │              │  EKS Control   │                       │  │
│  │              │     Plane      │                       │  │
│  │              │  (AWS Managed) │                       │  │
│  │              └────────────────┘                       │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Key Components**:
- **EKS Control Plane**: Fully managed by AWS, runs Kubernetes API server
- **Worker Nodes**: EC2 instances in private subnets running your workloads
- **NAT Gateways**: Allow outbound internet access from private subnets
- **Internet Gateway**: Provides public subnet internet connectivity
- **Public Subnets**: Host NAT gateways and future load balancers
- **Private Subnets**: Host EKS worker nodes for security

## Prerequisites

### Required Tools

You must have these tools installed on your local machine:

#### 1. AWS CLI (Latest Version)

**Linux/macOS**:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**Verify installation**:
```bash
aws --version
# Expected: aws-cli/2.x.x or higher
```

#### 2. Terraform (≥1.5.7)

**Linux**:
```bash
wget https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip
unzip terraform_1.6.6_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

**macOS**:
```bash
brew install terraform
```

**Verify installation**:
```bash
terraform version
# Expected: Terraform v1.5.7 or higher
```

#### 3. kubectl (Compatible with Kubernetes 1.32)

**Linux**:
```bash
curl -LO "https://dl.k8s.io/release/v1.32.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**macOS**:
```bash
brew install kubectl
```

**Verify installation**:
```bash
kubectl version --client
# Expected: v1.32.x or v1.33.x
```

### AWS Configuration

#### 1. Configure AWS Credentials

```bash
aws configure
```

You'll be prompted for:
- **AWS Access Key ID**: Your IAM user access key
- **AWS Secret Access Key**: Your IAM user secret key
- **Default region**: Recommend `us-east-1`
- **Default output format**: `json`

#### 2. Verify AWS Access

```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Required AWS IAM Permissions

Your IAM user or role needs these permissions:

**Minimum Required Policies**:
- `AmazonEC2FullAccess` - For VPC, subnets, security groups
- `IAMFullAccess` - For creating EKS service roles
- `AmazonS3FullAccess` - For creating and managing S3 bucket for Terraform state
- Custom policy for EKS (see below)

**Custom EKS Policy**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeAvailabilityZones",
                "ssm:GetParameter"
            ],
            "Resource": "*"
        }
    ]
}
```

### Verify Prerequisites

Before proceeding, verify all required tools are installed and configured:

#### 1. Check AWS CLI

```bash
aws --version
```

**Expected output**:
```
aws-cli/2.x.x Python/3.x.x ...
```

Should be version 2.x or higher.

#### 2. Check Terraform

```bash
terraform version
```

**Expected output**:
```
Terraform v1.6.6
on linux_amd64
```

Should be version 1.5.7 or higher.

#### 3. Check kubectl

```bash
kubectl version --client
```

**Expected output**:
```
Client Version: v1.32.0
```

Should be compatible with Kubernetes 1.32 (version 1.31-1.33).

#### 4. Verify AWS Credentials

```bash
aws sts get-caller-identity
```

**Expected output**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

This confirms your AWS credentials are configured correctly.

#### 5. Check AWS Region Configuration

```bash
aws configure get region
```

**Expected output**:
```
us-east-1
```

Should show your default region.

### Prerequisites Checklist

Before proceeding to deployment, confirm:

- [ ] AWS CLI version 2.x or higher installed
- [ ] Terraform version 1.5.7 or higher installed
- [ ] kubectl version 1.31-1.33 installed
- [ ] AWS credentials configured and valid
- [ ] AWS region set correctly
- [ ] IAM permissions verified (can create EKS, EC2, VPC, S3 resources)
- [ ] Environment variables will be set during deployment (PROJECT_NAME, AWS_ACCOUNT_ID, etc.)

## Project Structure

The project structure is already set up as follows:

```
01-eks-cluster/ (this project root)
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── terraform.tfvars     # Variable values (you'll create this)
└── README.md                # This document
```

## Terraform Configuration

The Terraform configuration files that define our EKS infrastructure are already created and ready for deployment.

### main.tf

The main Terraform configuration is already created in `terraform/main.tf`. This file contains:

- Terraform and AWS provider configuration
- VPC module configuration with public/private subnets and NAT gateways
- EKS module configuration with cluster, node groups, and IAM roles
- Required subnet tags for EKS subnet discovery

**File is ready for deployment** - see Deployment Instructions section below for the complete deployment process.

### variables.tf

The Terraform variables are already defined in `terraform/variables.tf`. This file contains:

- Required variables (cluster_name, aws_region)
- VPC configuration variables
- EKS cluster configuration variables
- Node group configuration variables
- Tagging variables with validation rules

**No additional commands needed** - variables are automatically loaded when running Terraform commands.

### outputs.tf

The Terraform outputs are already defined in `terraform/outputs.tf`. This file contains:

- Cluster outputs (name, endpoint, security group, IAM role, certificate data, version)
- Node group outputs (ID, status, security group)
- VPC outputs (VPC ID, subnet IDs)
- kubectl configuration command
- AWS region and account information

**View outputs after deployment:**
```bash
terraform output
```

### terraform.tfvars

The variable values are already configured in `terraform/terraform.tfvars`. This file contains:

- Cluster name and AWS region settings
- VPC CIDR configuration
- Kubernetes version (1.32)
- Node group configuration (instance types, scaling settings)
- Logging and tagging configuration

**Important**: Review and adjust the `cluster_name` in `terraform/terraform.tfvars` to be unique to your environment before deployment.

**No additional commands needed** - values are automatically loaded when running Terraform commands.

## Deployment Instructions

All Terraform configuration files are already in place. Let's deploy the EKS cluster.

### Step 1: Export Helper Variables and Configure S3 Backend

First, set up environment variables and create an S3 bucket for Terraform state:

```bash
# Export helper variables
export PROJECT_NAME="eks-poc"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export ENVIRONMENT="dev"
export AWS_REGION="us-east-1"

# Create S3 bucket name for Terraform state
export TF_STATE_BUCKET="${PROJECT_NAME}-tfstate-${AWS_ACCOUNT_ID}"

# Display the variables
echo "AWS_ACCOUNT_ID: ${AWS_ACCOUNT_ID}"
echo "TF_STATE_BUCKET: ${TF_STATE_BUCKET}"
echo "PROJECT_NAME: ${PROJECT_NAME}"
echo "ENVIRONMENT: ${ENVIRONMENT}"
echo "AWS_REGION: ${AWS_REGION}"

# Create S3 bucket for Terraform state
aws s3 mb "s3://${TF_STATE_BUCKET}" --region "${AWS_REGION}"

# Enable versioning on the bucket
aws s3api put-bucket-versioning --bucket "${TF_STATE_BUCKET}" --versioning-configuration Status=Enabled
```

**What happens**:
- Sets up environment variables for consistent naming
- Creates a unique S3 bucket name using your AWS account ID
- Creates the S3 bucket for storing Terraform state
- Enables versioning on the bucket for state file history

**Expected output**:
```
AWS_ACCOUNT_ID: 123456789012
TF_STATE_BUCKET: eks-poc-tfstate-123456789012
PROJECT_NAME: eks-poc
ENVIRONMENT: dev
AWS_REGION: us-east-1
make_bucket: eks-poc-tfstate-123456789012
```

### Step 2: Initialize Terraform with S3 Backend

Navigate to the terraform directory and initialize with the S3 backend:

```bash
cd terraform
terraform init -backend-config="bucket=${TF_STATE_BUCKET}" \
               -backend-config="key=${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate" \
               -backend-config="region=${AWS_REGION}"
```

**What happens**:
- Downloads AWS provider (v5.x)
- Downloads VPC module (v5.21.0)
- Downloads EKS module (v20.37.2)
- Creates `.terraform/` directory and lock file

**Expected output**:
```
Initializing modules...
Downloading terraform-aws-modules/vpc/aws 5.21.0 for vpc...
Downloading terraform-aws-modules/eks/aws 20.37.2 for eks...

Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 5.95.0, < 6.0.0"...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 3: Validate Configuration

```bash
terraform validate
```

**Expected output**:
```
Success! The configuration is valid.
```

If you see errors, review your configuration files for syntax issues.

### Step 4: Review the Execution Plan

```bash
terraform plan
```

**What to look for**:
- **~60+ resources** will be created
- VPC with 2 public and 2 private subnets
- NAT gateways (2, one per AZ)
- Internet gateway
- EKS cluster
- EKS node group
- IAM roles and policies
- Security groups

**Review carefully**: This plan shows exactly what will be created. Look for:
- Correct cluster name
- Correct region
- Correct instance types
- Correct number of nodes

### Step 5: Apply the Configuration

```bash
terraform apply
```

You'll be prompted to confirm. Type `yes` to proceed.

**Time estimate**: 15-20 minutes
- VPC resources: ~2 minutes
- EKS cluster: ~10-15 minutes
- Node group: ~3-5 minutes

**Progress indicators**:
```
module.vpc.aws_vpc.this: Creating...
module.vpc.aws_vpc.this: Creation complete after 2s
...
module.eks.aws_eks_cluster.this: Still creating... [10m0s elapsed]
module.eks.aws_eks_cluster.this: Creation complete after 12m30s
...
module.eks.eks_managed_node_group.main: Still creating... [3m0s elapsed]
module.eks.eks_managed_node_group.main: Creation complete after 4m20s
```

**Successful completion**:
```
Apply complete! Resources: 68 added, 0 changed, 0 destroyed.

Outputs:

cluster_name = "eks-cluster"
cluster_endpoint = "https://XXXXX.yl4.us-east-1.eks.amazonaws.com"
kubectl_config_command = "aws eks update-kubeconfig --region us-east-1 --name eks-cluster"
...
```

### Step 6: Configure kubectl

Use the output command to configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-cluster
```

**Expected output**:
```
Added new context arn:aws:eks:us-east-1:123456789012:cluster/eks-cluster to /home/user/.kube/config
```

**What this does**:
- Updates your `~/.kube/config` file
- Adds authentication token retrieval command
- Sets the current context to your new cluster

### Step 7: Verify Cluster Access

Check that kubectl can communicate with your cluster:

```bash
kubectl cluster-info
```

**Expected output**:
```
Kubernetes control plane is running at https://XXXXX.yl4.us-east-1.eks.amazonaws.com
CoreDNS is running at https://XXXXX.yl4.us-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### Step 8: Verify Nodes

Check that your worker nodes are ready:

```bash
kubectl get nodes
```

**Expected output**:
```
NAME                                           STATUS   ROLES    AGE   VERSION
ip-10-0-10-123.us-east-1.compute.internal     Ready    <none>   5m    v1.32.0-eks-xxxxx
ip-10-0-11-234.us-east-1.compute.internal     Ready    <none>   5m    v1.32.0-eks-xxxxx
```

**Key indicators**:
- STATUS should be `Ready`
- Should see 2 nodes (matching your desired_size)
- VERSION should match your Kubernetes version

### Step 9: Verify System Pods

Check that all system components are running:

```bash
kubectl get pods -A
```

**Expected output**:
```
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
kube-system   aws-node-xxxxx             2/2     Running   0          5m
kube-system   aws-node-yyyyy             2/2     Running   0          5m
kube-system   coredns-xxxxx              1/1     Running   0          10m
kube-system   coredns-yyyyy              1/1     Running   0          10m
kube-system   kube-proxy-xxxxx           1/1     Running   0          5m
kube-system   kube-proxy-yyyyy           1/1     Running   0          5m
```

**What you should see**:
- `aws-node` pods (VPC CNI) on each node
- `coredns` pods (2 replicas)
- `kube-proxy` pods on each node
- All pods in `Running` status with `READY` showing expected counts

### Step 10: Verify AWS Secrets Manager

AWS Secrets Manager secrets have been created and are ready for use:

```bash
# List secrets to verify they were created
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `app/config`)].Name'

# Expected output:
# [
#     "dev/app/config",
#     "prod/app/config"
# ]
```

**Note**: These secrets start empty and will be populated with real values when your applications need them. They will be consumed by External Secrets Operator in Project 2.

## Verification

Now let's verify that everything is working correctly by running individual verification commands.

### Step 1: Check Cluster Status

Verify the cluster is active in AWS:

```bash
aws eks describe-cluster --name eks-cluster --query 'cluster.status' --output text
```

**Expected output**:
```
ACTIVE
```

### Step 2: Check Cluster Connectivity

Verify kubectl can communicate with the cluster:

```bash
kubectl cluster-info
```

**Expected output**:
```
Kubernetes control plane is running at https://XXXXX.yl4.us-east-1.eks.amazonaws.com
CoreDNS is running at https://XXXXX.yl4.us-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

### Step 3: Check Node Status

Verify all nodes are ready:

```bash
kubectl get nodes
```

**Expected output**:
```
NAME                                           STATUS   ROLES    AGE   VERSION
ip-10-0-10-123.us-east-1.compute.internal     Ready    <none>   5m    v1.32.0-eks-xxxxx
ip-10-0-11-234.us-east-1.compute.internal     Ready    <none>   5m    v1.32.0-eks-xxxxx
```

**What to verify**:
- STATUS shows `Ready` for all nodes
- You see 2 nodes (matching your desired_size)
- VERSION matches your Kubernetes version (1.32.x)

### Step 4: Check Node Group Status

First, get the node group name and store it in a variable:

```bash
NODEGROUP_NAME=$(aws eks list-nodegroups --cluster-name eks-cluster --region us-east-1 --query 'nodegroups[0]' --output text)
```

Verify the variable was set correctly:

```bash
echo "Node group name: $NODEGROUP_NAME"
```

Verify the node group is active:

```bash
aws eks describe-nodegroup \
  --cluster-name eks-cluster \
  --nodegroup-name "$NODEGROUP_NAME" \
  --query 'nodegroup.status' --output text
```

**Expected output**:
```
ACTIVE
```

### Step 5: Check System Pods

Verify all system pods are running:

```bash
kubectl get pods -n kube-system
```

**Expected output**:
```
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
kube-system   aws-node-xxxxx             2/2     Running   0          5m
kube-system   aws-node-yyyyy             2/2     Running   0          5m
kube-system   coredns-xxxxx              1/1     Running   0          10m
kube-system   coredns-yyyyy              1/1     Running   0          10m
kube-system   kube-proxy-xxxxx           1/1     Running   0          5m
kube-system   kube-proxy-yyyyy           1/1     Running   0          5m
```

**What to verify**:
- `aws-node` pods (VPC CNI) - one per node, 2/2 ready
- `coredns` pods - 2 replicas, 1/1 ready each
- `kube-proxy` pods - one per node, 1/1 ready
- All pods show STATUS: `Running`

### Step 6: Check VPC CNI Addon

Verify the VPC CNI addon is healthy. The VPC CNI addon runs as pods with the label `k8s-app=aws-node`, so this command specifically filters for those pods:

```bash
kubectl get pods -n kube-system -l k8s-app=aws-node
```

**Expected output**:
```
NAME              READY   STATUS    RESTARTS   AGE
aws-node-xxxxx    2/2     Running   0          5m
aws-node-yyyyy    2/2     Running   0          5m
```

Should show one pod per node, all running.

### Step 7: Check CoreDNS

Verify CoreDNS is running. CoreDNS pods use the label `k8s-app=kube-dns`, so this command specifically filters for those pods:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**Expected output**:
```
NAME              READY   STATUS    RESTARTS   AGE
coredns-xxxxx     1/1     Running   0          10m
coredns-yyyyy     1/1     Running   0          10m
```

Should show 2 replicas, both running.

### Step 8: Check EKS Addons

List all installed addons:

```bash
aws eks list-addons --cluster-name eks-cluster
```

**Expected output**:
```json
{
    "addons": [
        "vpc-cni",
        "coredns",
        "kube-proxy"
    ]
}
```

Check addon versions and health:

```bash
aws eks describe-addon --cluster-name eks-cluster --addon-name vpc-cni --query 'addon.[addonVersion,status]' --output text
```

**Expected output**:
```
v1.x.x-eksbuild.x    ACTIVE
```

Repeat for `coredns` and `kube-proxy`.

### Step 9: Test DNS Resolution

Create a test pod to verify DNS is working:

```bash
kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes.default
```

**Expected output**:
```
Server:    10.0.0.10
Address 1: 10.0.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default
Address 1: 10.0.0.1 kubernetes.default.svc.cluster.local
```

If successful, DNS resolution is working correctly.

### Step 10: Get Cluster Version

Verify the Kubernetes version:

```bash
kubectl version 
```

**Expected output**:
```
Client Version: v1.32.0
Server Version: v1.32.0-eks-xxxxx
```

**Note**: Client and server versions should be within the compatible range (client can be 1-2 versions ahead or 1 version behind the server).

### Step 11: Check All Resources

Get a comprehensive view of all resources:

```bash
kubectl get all -A
```

This shows all pods, services, deployments, etc. across all namespaces.

### Step 12: View Cluster Details

Get detailed cluster information:

```bash
kubectl cluster-info dump | head -50
```

This shows extensive cluster configuration and status.

### Verification Checklist

Confirm each item:

- [ ] Cluster status is `ACTIVE`
- [ ] kubectl can connect to cluster
- [ ] All nodes show `Ready` status
- [ ] Node group status is `ACTIVE`
- [ ] All system pods are `Running`
- [ ] VPC CNI pods running (one per node)
- [ ] CoreDNS pods running (2 replicas)
- [ ] All addons are `ACTIVE`
- [ ] DNS resolution works
- [ ] Kubernetes version is correct (1.32.x)
- [ ] AWS Secrets Manager secrets created (empty, ready for real values)
- [ ] External Secrets IAM policy and role created

If all checks pass, **your EKS cluster is ready for Project 2!** 🎉

### Optional: Test Basic Functionality

Deploy a test pod to verify the cluster is functional:

```bash
# Create a simple nginx deployment
kubectl create deployment nginx --image=nginx:latest

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/nginx

# Check the pod
kubectl get pods -l app=nginx

# Check pod details
kubectl describe pod -l app=nginx

# Clean up the test
kubectl delete deployment nginx
```

If the nginx pod runs successfully, your cluster is fully functional!

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: kubectl cannot connect

**Symptoms**:
```
Unable to connect to the server: dial tcp: lookup XXX.eks.amazonaws.com: no such host
```

**Solutions**:
```bash
# 1. Verify cluster is active
aws eks describe-cluster --name eks-cluster --query 'cluster.status'

# 2. Reconfigure kubectl
aws eks update-kubeconfig --region us-east-1 --name eks-cluster --force

# 3. Check your AWS credentials
aws sts get-caller-identity

# 4. Verify cluster endpoint in config
kubectl config view
```

#### Issue 2: Nodes not ready

**Symptoms**:
```
NAME            STATUS     ROLES    AGE   VERSION
ip-10-0-10-123  NotReady   <none>   5m    v1.32.0
```

**Solutions**:
```bash
# 1. Check node events
kubectl describe node <node-name>

# 2. Check if aws-node (VPC CNI) is running
kubectl get pods -n kube-system -l k8s-app=aws-node

# 3. Check node logs in CloudWatch (if logging enabled)
# Or SSH to node and check /var/log/messages

# 4. Verify security group allows node-to-node communication
aws eks describe-cluster --name eks-cluster --query 'cluster.resourcesVpcConfig.clusterSecurityGroupId'

# 5. Wait longer - nodes can take 5-10 minutes to be ready
kubectl get nodes -w
```

#### Issue 3: CoreDNS pods pending

**Symptoms**:
```
coredns-xxxxx   0/1   Pending   0   5m
```

**Solutions**:
```bash
# 1. Check pod events
kubectl describe pod -n kube-system -l k8s-app=kube-dns

# 2. Common cause: insufficient node capacity
kubectl get nodes
kubectl describe nodes | grep -A 5 "Allocated resources"

# 3. Scale up node group if needed
# Edit terraform.tfvars to increase node_desired_size, then:
terraform apply
```

#### Issue 4: Terraform apply fails

**Error: insufficient IAM permissions**
```
Error: creating EKS Cluster: AccessDeniedException
```

**Solution**: Verify your IAM user has required permissions (see Prerequisites)

**Error: VPC CIDR overlap**
```
Error: VPC CIDR conflicts with existing VPC
```

**Solution**: Change `vpc_cidr` in terraform.tfvars to unused CIDR block

**Error: resource limit exceeded**
```
Error: LimitExceededException: VPC limit exceeded
```

**Solution**: Delete unused VPCs or request limit increase from AWS Support

#### Issue 5: Access denied after cluster creation

**Symptoms**:
```
error: You must be logged in to the server (Unauthorized)
```

**Cause**: Cluster creator admin permissions not enabled

**Solution**:
```bash
# Option 1: Enable via Terraform (recommended)
# In terraform.tfvars, ensure:
# enable_cluster_creator_admin_permissions = true
terraform apply

# Option 2: Add via AWS CLI
aws eks create-access-entry \
  --cluster-name eks-cluster \
  --principal-arn $(aws sts get-caller-identity --query Arn --output text)

# Option 3: Use AWS Console
# EKS → Clusters → your-cluster → Access → Create access entry
```

#### Issue 6: Node group name not found

**Symptoms**:
```
An error occurred (ResourceNotFoundException) when calling the DescribeNodegroup operation: No node group found for name: eks-cluster-node-group.
```

**Cause**: EKS node group names often include timestamps or suffixes that differ from the Terraform configuration

**Solution**:
```bash
# 1. List all node groups to get the actual name
aws eks list-nodegroups --cluster-name eks-cluster --region us-east-1

# 2. Use the actual node group name from the list
aws eks describe-nodegroup \
  --cluster-name eks-cluster \
  --nodegroup-name <actual-nodegroup-name> \
  --region us-east-1

# 3. Example with timestamp suffix:
aws eks describe-nodegroup \
  --cluster-name eks-cluster \
  --nodegroup-name eks-cluster-nodes-2025093015185205210000000d \
  --region us-east-1
```

### Getting Help

If you encounter issues not covered here:

1. **Check AWS EKS troubleshooting guide**:
   https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html

2. **Review Terraform module issues**:
   - EKS module: https://github.com/terraform-aws-modules/terraform-aws-eks/issues
   - VPC module: https://github.com/terraform-aws-modules/terraform-aws-vpc/issues

3. **Check CloudWatch logs** (if cluster logging enabled):
   ```bash
   aws logs tail /aws/eks/eks-cluster/cluster --follow
   ```

4. **Verify addon health**:
   ```bash
   aws eks describe-addon --cluster-name eks-cluster --addon-name vpc-cni
   aws eks describe-addon --cluster-name eks-cluster --addon-name coredns
   aws eks describe-addon --cluster-name eks-cluster --addon-name kube-proxy
   ```

## Cleanup

When you're ready to tear down the infrastructure:

### Step 1: Delete any resources created in the cluster

```bash
# Check for any deployments, services, etc.
kubectl get all -A

# Delete any resources you created (if any)
kubectl delete deployment <your-deployment-name>
kubectl delete service <your-service-name>

# Important: Delete any LoadBalancer services
# These create AWS Load Balancers that Terraform doesn't know about
kubectl get svc -A | grep LoadBalancer
```

### Step 2: Destroy the Terraform infrastructure

```bash
cd terraform
terraform destroy
```

Review the resources to be destroyed and type `yes` to confirm.

**Time estimate**: 10-15 minutes

**What gets deleted**:
- EKS node group
- EKS cluster
- VPC (subnets, route tables, NAT gateways, IGW)
- Security groups
- AWS Secrets Manager secrets (dev/app/config, prod/app/config)
- IAM policy for External Secrets Operator
- IAM role for External Secrets (IRSA)
- IAM roles and policies

**Expected output**:
```
Plan: 0 to add, 0 to change, 42 to destroy.
...
Destroy complete! Resources: 42 destroyed.
```

### Verify cleanup

```bash
# Verify cluster is deleted
aws eks describe-cluster --name eks-cluster
# Expected: ClusterNotFoundException

# Verify VPC is deleted
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=eks-cluster-vpc"
# Expected: Empty list
```

### Troubleshooting cleanup

**Issue**: Terraform destroy hangs or fails

**Common causes**:
1. LoadBalancer services still exist (creates ELB outside Terraform)
2. Volumes or other resources created by Kubernetes still exist

**Solution**:
```bash
# 1. Manually delete LoadBalancer services
kubectl delete svc --all -A

# 2. Manually delete any PVCs
kubectl delete pvc --all -A

# 3. Wait a few minutes for AWS to clean up

# 4. Try terraform destroy again
terraform destroy

# 5. If still stuck, use targeted destruction
terraform destroy -target=module.eks
terraform destroy -target=module.vpc
```

## Cost Considerations

Understanding the AWS costs for this setup:

### Hourly Costs

| Resource | Cost per hour | Notes |
|----------|---------------|-------|
| EKS Control Plane | $0.10 | Per cluster, regardless of size |
| EC2 t3.medium (×2) | $0.0832 | 2 nodes × $0.0416/hour |
| NAT Gateway (×2) | $0.090 | 2 NAT gateways × $0.045/hour |
| EBS Volumes (×2) | ~$0.003 | 40GB total × $0.10/GB/month |
| **Total** | **~$0.276/hour** | **~$199/month** |

### Additional Costs for Secrets Manager

| Resource | Cost | Notes |
|----------|------|-------|
| AWS Secrets Manager (×2) | ~$0.80/month | $0.40 per secret for dev/prod configs |
| API calls | ~$0.05/month | First 10,000 calls included, then $0.05/10K |

**Total with Secrets Manager**: ~$200-201/month

### Additional Costs (Optional)

- **Data Transfer**: First 100GB free, then $0.09/GB out
- **Control Plane Logging**: ~$0.50/GB ingested to CloudWatch
- **EBS Snapshots**: $0.05/GB/month
- **NAT Gateway Data**: $0.045/GB processed

### Cost Optimization Tips

1. **Stop the cluster when not in use**:
   ```bash
   # Scale nodes to 0 (saves EC2 costs, but EKS control plane still charged)
   terraform apply -var="node_desired_size=0" -var="node_min_size=0"
   ```

2. **Use single NAT gateway** (lower availability):
   ```hcl
   # In main.tf vpc module:
   single_nat_gateway = true  # Saves $0.045/hour
   ```

3. **Use smaller instances for testing**:
   ```hcl
   # In terraform.tfvars:
   node_instance_types = ["t3.small"]  # $0.0208/hour vs $0.0416/hour
   ```

4. **Disable control plane logging**:
   ```hcl
   # In terraform.tfvars:
   enable_cluster_logging = false  # Already default
   ```

5. **Destroy when not needed**:
   ```bash
   terraform destroy  # $0/hour when destroyed
   ```

### Free Tier

AWS Free Tier includes:
- 750 hours/month EC2 t2.micro (not t3.medium)
- EKS not included in free tier
- Some data transfer included

This setup exceeds free tier limits.

## Security Best Practices

### Current Security Posture

This deployment includes several security best practices:

**✅ Implemented**:
- Private subnets for worker nodes
- NAT gateways for outbound traffic only
- EKS Access Entries for authentication (modern approach)
- Cluster creator admin permissions properly configured
- Amazon Linux 2023 (receives security updates)
- Multi-AZ deployment for availability
- Managed node groups (AWS handles security patches)

**⚠️ Development Configuration** (acceptable for POC):
- Public API endpoint enabled (convenient for development)
- No pod security policies configured
- No network policies configured
- Control plane logging disabled (cost savings)

### Enhanced Security for Production

For production workloads, consider these enhancements:

#### 1. Private API Endpoint Only

```hcl
# In terraform.tfvars:
cluster_endpoint_public_access  = false  # Access only via VPN/Direct Connect
cluster_endpoint_private_access = true
```

#### 2. Enable Control Plane Logging

```hcl
# In terraform.tfvars:
enable_cluster_logging = true  # Audit API calls and authentication
```

#### 3. Enable Encryption at Rest

```hcl
# In main.tf eks module, add:
cluster_encryption_config = {
  resources        = ["secrets"]
  provider_key_arn = aws_kms_key.eks.arn  # Create KMS key separately
}
```

#### 4. Use IRSA for Workload IAM

Instead of attaching policies to node IAM role, use IAM Roles for Service Accounts (IRSA):

```bash
# Enable OIDC provider (add to main.tf):
enable_irsa = true

# Then create service account with IAM role
# (Will cover in future projects)
```

#### 5. Implement Pod Security Standards

```bash
# Will configure in future projects when deploying workloads
# Enforce baseline, restricted policies per namespace
```

### Security Checklist

Before moving to production:

- [ ] Review and restrict API endpoint access
- [ ] Enable control plane logging
- [ ] Configure encryption at rest for secrets
- [ ] Implement IRSA for all workload IAM needs
- [ ] Configure Pod Security Standards
- [ ] Enable Network Policies
- [ ] Set up AWS GuardDuty for EKS
- [ ] Configure CloudTrail for API auditing
- [ ] Implement least-privilege IAM policies
- [ ] Enable AWS Security Hub

## Next Steps

**Congratulations!** 🎉 You now have a production-ready EKS cluster running.

### What You Accomplished

- ✅ Deployed a fully-managed Kubernetes cluster
- ✅ Configured proper networking with public and private subnets
- ✅ Set up multi-AZ deployment for high availability
- ✅ Configured kubectl for cluster access
- ✅ Verified all system components are running

### Project 2 Preview

In the next project, you'll:
- Create Helm charts for application deployment
- Set up development and production environments (Kubernetes namespaces)
- Deploy applications to different environments
- Implement environment promotion workflows

**Ready to continue?** → Proceed to **Project 2 - Helm Charts & Dev/Prod Environments**

### Additional Learning Resources

- **AWS EKS Best Practices Guide**: https://aws.github.io/aws-eks-best-practices/
- **Terraform AWS EKS Module Docs**: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws
- **Kubernetes Documentation**: https://kubernetes.io/docs/home/
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet/

### Community and Support

- **AWS EKS Troubleshooting**: https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html
- **Terraform Discussion Forum**: https://discuss.hashicorp.com/c/terraform-core
- **Kubernetes Slack**: https://kubernetes.slack.com

---

## Appendix

### Terraform State Management

This project uses **S3 backend for remote state storage** by default, which is the recommended approach for production environments.

**Current Configuration**:
- State is stored in S3 bucket: `${PROJECT_NAME}-tfstate-${AWS_ACCOUNT_ID}`
- State file path: `${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate`
- Versioning is enabled on the S3 bucket
- State is initialized with backend configuration during deployment

**For additional production features**, you can add DynamoDB for state locking:

```hcl
# Add to main.tf terraform block:
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "eks-cluster/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"  # Optional: for state locking
}
```

### Useful kubectl Commands

```bash
# Get all resources in all namespaces
kubectl get all -A

# Describe a specific resource
kubectl describe node <node-name>
kubectl describe pod <pod-name> -n <namespace>

# Get resource usage (requires metrics-server)
kubectl top nodes
kubectl top pods -A

# View logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous container logs

# Execute command in pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Get cluster events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Get node conditions
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[-1].type,REASON:.status.conditions[-1].reason
```

### Kubernetes Version Support

EKS supported versions (as of September 2025):
- **1.33** - Latest (released May 2025)
- **1.32** - Recommended for production (stable)
- **1.31** - Supported (EOL ~Feb 2026)
- **1.30** - Supported (EOL ~Nov 2025)

Plan to upgrade yearly. Each version is supported for ~14 months.

### AWS Resource Limits

Default limits that may affect deployment:
- **VPCs per region**: 5
- **EIPs per region**: 5  
- **NAT gateways per AZ**: 5
- **EC2 instances**: Varies by instance type

Request increases via AWS Support if needed.

---

**Document Version**: 1.0  
**Last Updated**: Based on AWS EKS module v20.37.2 (September 2025)  
**Terraform Version**: ≥1.5.7  
**Kubernetes Version**: 1.32

