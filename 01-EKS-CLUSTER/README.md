# Project 1 - EKS Cluster Deployment

## Overview

**Project Goal**: Deploy an Amazon EKS (Elastic Kubernetes Service) cluster that serves as the foundation for subsequent DevOps projects.

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

