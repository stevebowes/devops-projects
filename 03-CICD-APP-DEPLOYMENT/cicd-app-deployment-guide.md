# Project 3 - Sample Application Deployment with CI/CD Pipeline

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Sample Application](#sample-application)
- [Container Configuration](#container-configuration)
- [ECR Setup](#ecr-setup)
- [CodeBuild Pipeline](#codebuild-pipeline)
- [GitOps Integration](#gitops-integration)
- [Helm Chart Updates](#helm-chart-updates)
- [Deployment Instructions](#deployment-instructions)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Next Steps](#next-steps)

## Overview

**Project Goal**: Deploy a secure, production-ready sample application with fully automated CI/CD pipeline that integrates with the existing GitOps infrastructure from Projects 1 and 2.

**What You'll Build**:
- Simple Node.js REST API with health checks and metrics endpoints
- Multi-stage Docker container with security hardening
- ECR repository with lifecycle policies and image scanning
- CodeBuild CI/CD pipeline triggered on git push
- Automated security scanning with Trivy
- GitOps deployment via ArgoCD from Project 2
- Automated image tag updates and deployments

**Success Criteria**:
- ✅ Sample application runs in both dev and prod namespaces
- ✅ Container images stored in ECR with security scanning
- ✅ CodeBuild pipeline triggers automatically on git push
- ✅ Security scans block deployment on critical vulnerabilities
- ✅ ArgoCD automatically deploys new image versions
- ✅ Application compliant with Pod Security Standards
- ✅ Health checks and readiness probes functional
- ✅ Rolling updates with zero downtime

**Time Estimate**: 3-4 hours total
- Sample app creation: ~30 minutes
- Container setup: ~30 minutes
- Infrastructure (ECR + CodeBuild): ~45 minutes
- Pipeline configuration: ~45 minutes
- GitOps integration: ~30 minutes
- Testing and verification: ~30 minutes

**Important Notes**:
- **Packer Clarification**: This project uses Docker for container images, not Packer. Packer is used for building AMIs (EC2 images). For containers on EKS, Docker is the standard tool. Packer can optionally be used for custom EKS node AMIs (advanced topic, not covered here).
- This project assumes Projects 1 and 2 are complete
- Uses Node.js 20 LTS for the sample application
- Implements security best practices throughout

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Workflow                           │
│                                                                  │
│  Developer ──(git push)──> GitHub Repository                    │
│                                  │                               │
│                                  │ (webhook)                     │
│                                  ▼                               │
│                        ┌──────────────────┐                     │
│                        │  AWS CodeBuild   │                     │
│                        │                  │                     │
│                        │ 1. Build image   │                     │
│                        │ 2. Scan (Trivy)  │                     │
│                        │ 3. Push to ECR   │                     │
│                        │ 4. Update GitOps │                     │
│                        └──────────────────┘                     │
│                                  │                               │
│                     ┌────────────┴────────────┐                 │
│                     │                         │                 │
│                     ▼                         ▼                 │
│            ┌──────────────┐         ┌─────────────────┐        │
│            │     ECR      │         │  GitOps Repo    │        │
│            │              │         │  (manifests)    │        │
│            │ [v1.2.3]     │         │                 │        │
│            │ [v1.2.4]     │         │ Updated with    │        │
│            │ [latest]     │         │ new image tag   │        │
│            └──────────────┘         └─────────────────┘        │
│                     │                         │                 │
│                     │                         │                 │
│                     │            ┌────────────▼──────────┐      │
│                     │            │       ArgoCD          │      │
│                     │            │                       │      │
│                     │            │ Monitors GitOps repo  │      │
│                     │            │ Syncs to cluster      │      │
│                     │            └───────────────────────┘      │
│                     │                         │                 │
│                     └─────────────────────────┘                 │
│                                  │                               │
│                                  ▼                               │
│                    ┌───────────────────────────┐                │
│                    │      EKS Cluster          │                │
│                    │                           │                │
│                    │  ┌─────────────────────┐  │                │
│                    │  │ Development NS      │  │                │
│                    │  │                     │  │                │
│                    │  │ [sample-app pods]   │  │                │
│                    │  └─────────────────────┘  │                │
│                    │                           │                │
│                    │  ┌─────────────────────┐  │                │
│                    │  │ Production NS       │  │                │
│                    │  │                     │  │                │
│                    │  │ [sample-app pods]   │  │                │
│                    │  └─────────────────────┘  │                │
│                    └───────────────────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

**Key Components**:
- **Sample Application**: Node.js REST API with health and metrics endpoints
- **GitHub Repository**: Source code and GitOps manifests
- **CodeBuild**: Automated build, scan, and push pipeline
- **ECR**: Private container registry with scanning and lifecycle policies
- **ArgoCD**: GitOps continuous delivery from Project 2
- **EKS Cluster**: Target environment from Projects 1 and 2

## Prerequisites

### Required: Projects 1 and 2 Complete

You must have completed Projects 1 and 2 before starting this project.

**From Project 1**:
- Working EKS cluster running Kubernetes 1.32
- kubectl configured and connected
- VPC with proper subnet tags

**From Project 2**:
- Development and production namespaces with Pod Security Standards
- ArgoCD installed and operational
- Helm charts with security contexts
- External Secrets Operator configured (optional but recommended)
- Network policies in place

### Verify Prerequisites

```bash
# Check EKS cluster
kubectl get nodes
# Expected: 2+ nodes in Ready state

# Check namespaces
kubectl get namespaces | grep -E "development|production|monitoring"
# Expected: All three namespaces exist

# Check ArgoCD
kubectl get pods -n monitoring -l app.kubernetes.io/name=argocd-server
# Expected: ArgoCD server pod running

# Check Helm charts exist
ls -la helm-charts/app-chart/
# Expected: Chart structure from Project 2
```

### Required Tools

All tools from Projects 1 and 2, plus:

#### 1. Docker (for local testing)

**Linux**:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes
```

**macOS**:
```bash
brew install --cask docker
# Start Docker Desktop
```

**Verify**:
```bash
docker --version
# Expected: Docker version 24.x or higher
```

#### 2. Node.js (for local development)

**Linux/macOS**:
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc  # or ~/.zshrc for macOS
nvm install 20
nvm use 20
```

**Verify**:
```bash
node --version
# Expected: v20.x.x

npm --version
# Expected: 10.x.x
```

#### 3. Trivy (for local security scanning)

**Linux**:
```bash
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

**macOS**:
```bash
brew install trivy
```

**Verify**:
```bash
trivy --version
# Expected: Version: 0.50.x or higher
```

### AWS Configuration

Verify AWS credentials and permissions:

```bash
# Check AWS identity
aws sts get-caller-identity

# Verify ECR permissions
aws ecr describe-repositories --region us-west-2 || echo "Need ECR permissions"

# Verify CodeBuild permissions
aws codebuild list-projects --region us-west-2 || echo "Need CodeBuild permissions"
```

### GitHub Repository Setup

You'll need a GitHub repository for this project:

```bash
# Create a new repository on GitHub named 'sample-app'
# Then clone it locally
git clone https://github.com/YOUR_USERNAME/sample-app.git
cd sample-app
```

### Prerequisites Checklist

- [ ] Project 1 complete (EKS cluster running)
- [ ] Project 2 complete (Namespaces, ArgoCD, Helm charts)
- [ ] Docker installed and running
- [ ] Node.js 20 LTS installed
- [ ] Trivy installed for security scanning
- [ ] AWS CLI configured with ECR and CodeBuild permissions
- [ ] GitHub repository created
- [ ] kubectl connected to cluster

## Project Structure

Create the following directory structure:

```bash
mkdir -p sample-app
cd sample-app

# Application structure
mkdir -p src
mkdir -p tests
mkdir -p scripts
mkdir -p .github/workflows

# Infrastructure structure
mkdir -p terraform
mkdir -p kubernetes
```

**Complete structure**:
```
sample-app/
├── src/
│   ├── server.js           # Main application
│   ├── routes.js           # API routes
│   └── config.js           # Configuration
├── tests/
│   └── server.test.js      # Unit tests
├── scripts/
│   ├── update-image-tag.sh # GitOps image updater
│   └── deploy-local.sh     # Local deployment helper
├── terraform/
│   ├── ecr.tf              # ECR repository
│   ├── codebuild.tf        # CodeBuild project
│   ├── iam.tf              # IAM roles
│   ├── variables.tf        # Variables
│   └── outputs.tf          # Outputs
├── kubernetes/
│   └── application.yaml    # ArgoCD Application manifest
├── Dockerfile              # Multi-stage container build
├── .dockerignore           # Docker ignore file
├── buildspec.yml           # CodeBuild specification
├── package.json            # Node.js dependencies
├── package-lock.json       # Dependency lock file
└── README.md               # Project documentation
```

## Sample Application

Now let's create a simple but production-ready Node.js REST API.

### package.json

Create `package.json`:

```json
{
  "name": "sample-app",
  "version": "1.0.0",
  "description": "Sample REST API for EKS DevOps project",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js",
    "test": "jest"
  },
  "keywords": ["api", "express", "kubernetes"],
  "author": "Your Name",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^15.1.0",
    "winston": "^3.11.0"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "nodemon": "^3.0.2",
    "supertest": "^6.3.3"
  }
}
```

### src/config.js

Create `src/config.js`:

```javascript
// Configuration with environment variables
module.exports = {
  port: process.env.PORT || 3000,
  env: process.env.NODE_ENV || 'development',
  logLevel: process.env.LOG_LEVEL || 'info',
  appName: 'sample-app',
  version: process.env.APP_VERSION || '1.0.0'
};
```

### src/server.js

Create `src/server.js`:

```javascript
const express = require('express');
const promClient = require('prom-client');
const winston = require('winston');
const config = require('./config');

// Initialize Express app
const app = express();
app.use(express.json());

// Configure logging
const logger = winston.createLogger({
  level: config.logLevel,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// In-memory data store (for demo purposes)
let items = [
  { id: 1, name: 'Item 1', description: 'First item' },
  { id: 2, name: 'Item 2', description: 'Second item' }
];
let nextId = 3;

// Middleware for metrics
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
  });
  next();
});

// Health check endpoint (liveness probe)
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  // In a real app, check database connections, etc.
  res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
});

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// API info endpoint
app.get('/', (req, res) => {
  res.json({
    name: config.appName,
    version: config.version,
    environment: config.env,
    endpoints: {
      health: '/health',
      ready: '/ready',
      metrics: '/metrics',
      items: '/api/items'
    }
  });
});

// GET all items
app.get('/api/items', (req, res) => {
  logger.info('Fetching all items', { count: items.length });
  res.json(items);
});

// GET single item
app.get('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const item = items.find(i => i.id === id);
  
  if (!item) {
    logger.warn('Item not found', { id });
    return res.status(404).json({ error: 'Item not found' });
  }
  
  logger.info('Fetched item', { id });
  res.json(item);
});

// POST new item
app.post('/api/items', (req, res) => {
  const { name, description } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Name is required' });
  }
  
  const newItem = {
    id: nextId++,
    name,
    description: description || ''
  };
  
  items.push(newItem);
  logger.info('Created new item', { id: newItem.id, name });
  res.status(201).json(newItem);
});

// PUT update item
app.put('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex(i => i.id === id);
  
  if (itemIndex === -1) {
    logger.warn('Item not found for update', { id });
    return res.status(404).json({ error: 'Item not found' });
  }
  
  const { name, description } = req.body;
  items[itemIndex] = {
    id,
    name: name || items[itemIndex].name,
    description: description !== undefined ? description : items[itemIndex].description
  };
  
  logger.info('Updated item', { id });
  res.json(items[itemIndex]);
});

// DELETE item
app.delete('/api/items/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const itemIndex = items.findIndex(i => i.id === id);
  
  if (itemIndex === -1) {
    logger.warn('Item not found for deletion', { id });
    return res.status(404).json({ error: 'Item not found' });
  }
  
  items.splice(itemIndex, 1);
  logger.info('Deleted item', { id });
  res.status(204).send();
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

// Graceful shutdown
const server = app.listen(config.port, () => {
  logger.info(`Server started`, {
    port: config.port,
    environment: config.env,
    version: config.version
  });
});

process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received, closing server gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

module.exports = app;
```

### Tests

Create `tests/server.test.js`:

```javascript
const request = require('supertest');
const app = require('../src/server');

describe('Sample App API', () => {
  describe('Health Endpoints', () => {
    it('should return healthy status', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('healthy');
    });

    it('should return ready status', async () => {
      const res = await request(app).get('/ready');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('ready');
    });
  });

  describe('Items API', () => {
    it('should get all items', async () => {
      const res = await request(app).get('/api/items');
      expect(res.statusCode).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('should create a new item', async () => {
      const res = await request(app)
        .post('/api/items')
        .send({ name: 'Test Item', description: 'Test Description' });
      expect(res.statusCode).toBe(201);
      expect(res.body.name).toBe('Test Item');
    });
  });
});
```

### Local Testing

Test the application locally:

```bash
# Install dependencies
npm install

# Run locally
npm start

# In another terminal, test endpoints
curl http://localhost:3000/health
curl http://localhost:3000/api/items
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Testing"}'

# Run tests
npm test
```

## Container Configuration

Now let's create a secure, optimized Docker container.

### .dockerignore

Create `.dockerignore`:

```
node_modules
npm-debug.log
.git
.gitignore
.env
.env.*
README.md
.dockerignore
Dockerfile
.github
tests
*.test.js
coverage
.vscode
.idea
terraform
kubernetes
scripts
buildspec.yml
```

### Dockerfile

Create `Dockerfile` with multi-stage build:

```dockerfile
# ============================================================================
# Stage 1: Builder - Install dependencies and build
# ============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (including dev dependencies for build)
RUN npm ci

# Copy application source
COPY src/ ./src/

# ============================================================================
# Stage 2: Dependencies - Production dependencies only
# ============================================================================
FROM node:20-alpine AS dependencies

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production && \
    npm cache clean --force

# ============================================================================
# Stage 3: Runtime - Distroless for security
# ============================================================================
FROM gcr.io/distroless/nodejs20-debian12:nonroot

# Set working directory
WORKDIR /app

# Copy production dependencies from dependencies stage
COPY --from=dependencies --chown=nonroot:nonroot /app/node_modules ./node_modules

# Copy package.json for version info
COPY --from=builder --chown=nonroot:nonroot /app/package*.json ./

# Copy application source
COPY --from=builder --chown=nonroot:nonroot /app/src ./src

# Use non-root user (already set by distroless :nonroot tag)
# USER nonroot:nonroot is implicit

# Expose application port
EXPOSE 3000

# Environment variables
ENV NODE_ENV=production \
    PORT=3000 \
    LOG_LEVEL=info

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/nodejs/bin/node", "-e", "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"]

# Start application
CMD ["src/server.js"]
```

### Build and Test Locally

```bash
# Build the container
docker build -t sample-app:local .

# Run locally
docker run -d -p 3000:3000 --name sample-app-test sample-app:local

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3000/api/items

# Check logs
docker logs sample-app-test

# Scan for vulnerabilities with Trivy
trivy image sample-app:local

# Clean up
docker stop sample-app-test
docker rm sample-app-test
```

Expected Trivy output should show no HIGH or CRITICAL vulnerabilities due to distroless base image.

## ECR Setup

Now let's create the ECR repository using Terraform.

### terraform/ecr.tf

Create `terraform/ecr.tf`:

```hcl
###############################################################################
# ECR Repository for Sample Application
###############################################################################

resource "aws_ecr_repository" "sample_app" {
  name                 = "sample-app"
  image_tag_mutability = "IMMUTABLE"  # Prevent tag overwrites

  # Enable image scanning on push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Enable encryption at rest
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.ecr.arn
  }

  tags = merge(
    var.tags,
    {
      Name = "sample-app-ecr"
    }
  )
}

###############################################################################
# KMS Key for ECR Encryption
###############################################################################

resource "aws_kms_key" "ecr" {
  description             = "KMS key for ECR encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "ecr-encryption-key"
    }
  )
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/ecr-sample-app"
  target_key_id = aws_kms_key.ecr.key_id
}

###############################################################################
# ECR Lifecycle Policy
###############################################################################

resource "aws_ecr_lifecycle_policy" "sample_app" {
  repository = aws_ecr_repository.sample_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 production images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 development images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-"]
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

###############################################################################
# ECR Repository Policy (Optional - for cross-account access)
###############################################################################

# Uncomment if you need cross-account access
# resource "aws_ecr_repository_policy" "sample_app" {
#   repository = aws_ecr_repository.sample_app.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowPull"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::ACCOUNT_ID:root"
#         }
#         Action = [
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage",
#           "ecr:BatchCheckLayerAvailability"
#         ]
#       }
#     ]
#   })
# }
```

### terraform/iam.tf

Create `terraform/iam.tf` for CodeBuild service role:

```hcl
###############################################################################
# IAM Role for CodeBuild
###############################################################################

resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

###############################################################################
# IAM Policy for CodeBuild
###############################################################################

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.codebuild_cache.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.ecr.arn
      }
    ]
  })
}

###############################################################################
# Data Sources
###############################################################################

data "aws_caller_identity" "current" {}
```

### terraform/codebuild.tf

Create `terraform/codebuild.tf`:

```hcl
###############################################################################
# S3 Bucket for CodeBuild Cache
###############################################################################

resource "aws_s3_bucket" "codebuild_cache" {
  bucket = "${var.project_name}-codebuild-cache-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "codebuild-cache"
    }
  )
}

resource "aws_s3_bucket_versioning" "codebuild_cache" {
  bucket = aws_s3_bucket.codebuild_cache.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codebuild_cache" {
  bucket = aws_s3_bucket.codebuild_cache.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codebuild_cache" {
  bucket = aws_s3_bucket.codebuild_cache.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###############################################################################
# CodeBuild Project
###############################################################################

resource "aws_codebuild_project" "sample_app" {
  name          = "${var.project_name}-build"
  description   = "Build project for sample application"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 30  # minutes

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.codebuild_cache.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/standard:7.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode            = true  # Required for Docker builds

    environment_variable {
      name  = "ECR_REPOSITORY_URI"
      value = aws_ecr_repository.sample_app.repository_url
    }

    environment_variable {
      name  = "ECR_REPOSITORY_NAME"
      value = aws_ecr_repository.sample_app.name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  }

  source {
    type            = "GITHUB"
    location        = var.github_repo_url
    git_clone_depth = 1
    buildspec       = "buildspec.yml"

    git_submodules_config {
      fetch_submodules = false
    }
  }

  source_version = "main"  # or "master" depending on your default branch

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.project_name}"
      stream_name = "build-log"
    }
  }

  tags = var.tags
}

###############################################################################
# CloudWatch Log Group
###############################################################################

resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}"
  retention_in_days = 7

  tags = var.tags
}

###############################################################################
# CodeBuild Webhook (GitHub integration)
###############################################################################

resource "aws_codebuild_webhook" "sample_app" {
  project_name = aws_codebuild_project.sample_app.name

  filter_group {
    filter {
      type    = "EVENT"
      pattern = "PUSH"
    }

    filter {
      type    = "HEAD_REF"
      pattern = "refs/heads/main"  # Trigger only on main branch
    }
  }
}
```

### terraform/variables.tf

Create `terraform/variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "sample-app"
}

variable "github_repo_url" {
  description = "GitHub repository URL for the sample application"
  type        = string
  # Example: "https://github.com/username/sample-app.git"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "eks-devops"
    Environment = "development"
    ManagedBy   = "terraform"
  }
}
```

### terraform/outputs.tf

Create `terraform/outputs.tf`:

```hcl
output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.sample_app.repository_url
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = aws_ecr_repository.sample_app.arn
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.sample_app.name
}

output "codebuild_project_arn" {
  description = "CodeBuild project ARN"
  value       = aws_codebuild_project.sample_app.arn
}

output "codebuild_role_arn" {
  description = "CodeBuild IAM role ARN"
  value       = aws_iam_role.codebuild.arn
}

output "codebuild_webhook_url" {
  description = "CodeBuild webhook URL for GitHub"
  value       = aws_codebuild_webhook.sample_app.payload_url
}
```

### terraform/terraform.tfvars

Create `terraform/terraform.tfvars`:

```hcl
aws_region      = "us-west-2"
project_name    = "sample-app"
github_repo_url = "https://github.com/YOUR_USERNAME/sample-app.git"

tags = {
  Project     = "eks-devops-project3"
  Environment = "development"
  ManagedBy   = "terraform"
}
```

**Important**: Replace `YOUR_USERNAME` with your actual GitHub username.

## CodeBuild Pipeline

### buildspec.yml

Create `buildspec.yml` in the root of your repository:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY_URI
      - echo Installing Trivy for security scanning...
      - |
        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
        apt-get update
        apt-get install -y trivy
      - COMMIT_HASH=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)
      - IMAGE_TAG=${IMAGE_TAG:-$COMMIT_HASH}
      - echo Build started on `date`
      - echo Building Docker image with tag $IMAGE_TAG...

  build:
    commands:
      - echo Building the Docker image...
      - docker build -t $ECR_REPOSITORY_URI:latest .
      - docker tag $ECR_REPOSITORY_URI:latest $ECR_REPOSITORY_URI:$IMAGE_TAG
      - docker tag $ECR_REPOSITORY_URI:latest $ECR_REPOSITORY_URI:$COMMIT_HASH

  post_build:
    commands:
      - echo Build completed on `date`
      - echo Scanning image for vulnerabilities...
      - |
        trivy image --severity HIGH,CRITICAL --exit-code 1 $ECR_REPOSITORY_URI:$IMAGE_TAG || {
          echo "Security scan found HIGH or CRITICAL vulnerabilities!"
          echo "Build will fail. Review vulnerabilities and fix before deploying."
          exit 1
        }
      - echo Security scan passed!
      - echo Pushing Docker images to ECR...
      - docker push $ECR_REPOSITORY_URI:latest
      - docker push $ECR_REPOSITORY_URI:$IMAGE_TAG
      - docker push $ECR_REPOSITORY_URI:$COMMIT_HASH
      - echo Docker images pushed successfully
      - echo Writing image definitions file...
      - printf '[{"name":"sample-app","imageUri":"%s"}]' $ECR_REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

**Key Features**:
- Logs into ECR
- Installs Trivy for security scanning
- Builds Docker image with multiple tags (latest, commit hash, custom tag)
- Scans image and fails build on HIGH/CRITICAL vulnerabilities
- Pushes images to ECR
- Creates imagedefinitions.json for deployment tracking

### Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan infrastructure changes
terraform plan

# Apply configuration
terraform apply
```

Review the plan and type `yes` to confirm.

**Expected output**:
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

codebuild_project_name = "sample-app-build"
codebuild_webhook_url = "https://codebuild.us-west-2.amazonaws.com/webhooks?..."
ecr_repository_url = "123456789012.dkr.ecr.us-west-2.amazonaws.com/sample-app"
```

### Configure GitHub Webhook

The Terraform webhook resource creates the webhook automatically, but you need to ensure your GitHub repository has access:

```bash
# Get the webhook URL
terraform output codebuild_webhook_url

# Verify webhook in GitHub:
# Go to: Settings → Webhooks
# You should see a webhook pointing to CodeBuild
```

### Test the Pipeline

```bash
# Commit and push code to trigger build
git add .
git commit -m "Initial application commit"
git push origin main

# Monitor the build
aws codebuild list-builds-for-project --project-name sample-app-build

# Get build details
BUILD_ID=$(aws codebuild list-builds-for-project --project-name sample-app-build --query 'ids[0]' --output text)
aws codebuild batch-get-builds --ids $BUILD_ID

# Stream logs
aws logs tail /aws/codebuild/sample-app --follow
```

## GitOps Integration

Now we'll integrate with ArgoCD from Project 2.

### Update Helm Values

First, update your Helm chart values files from Project 2 to reference the ECR image.

Edit `helm-charts/app-chart/values/dev.yaml`:

```yaml
# Development environment values
replicaCount: 1

image:
  repository: 123456789012.dkr.ecr.us-west-2.amazonaws.com/sample-app
  tag: "latest"
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80
  targetPort: 3000

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Security context for development (Baseline PSS)
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  fsGroup: 65532

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65532
  capabilities:
    drop:
      - ALL

# Health checks
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5

# Environment variables
env:
  - name: NODE_ENV
    value: "development"
  - name: LOG_LEVEL
    value: "debug"
  - name: PORT
    value: "3000"

# Volumes for read-only root filesystem
volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}

volumeMounts:
  - name: tmp
    mountPath: /tmp
  - name: cache
    mountPath: /app/.npm

# Monitoring
metrics:
  enabled: true
  port: 3000
  path: /metrics

# HPA disabled in dev
autoscaling:
  enabled: false
```

Edit `helm-charts/app-chart/values/prod.yaml`:

```yaml
# Production environment values
replicaCount: 3

image:
  repository: 123456789012.dkr.ecr.us-west-2.amazonaws.com/sample-app
  tag: "v1.0.0"  # Will be updated by CI/CD
  pullPolicy: IfNotPresent

service:
  type: LoadBalancer
  port: 80
  targetPort: 3000
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

# Security context for production (Restricted PSS)
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
  fsGroup: 65532
  seccompProfile:
    type: RuntimeDefault

containerSecurityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 65532
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault

# Health checks
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

# Environment variables
env:
  - name: NODE_ENV
    value: "production"
  - name: LOG_LEVEL
    value: "info"
  - name: PORT
    value: "3000"

# Volumes for read-only root filesystem
volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}

volumeMounts:
  - name: tmp
    mountPath: /tmp
  - name: cache
    mountPath: /app/.npm

# Monitoring
metrics:
  enabled: true
  port: 3000
  path: /metrics

# HPA configuration
autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

# Pod Disruption Budget
podDisruptionBudget:
  enabled: true
  minAvailable: 2

# Pod anti-affinity for node distribution
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - sample-app
          topologyKey: kubernetes.io/hostname
```

**Important**: Replace `123456789012` with your actual AWS account ID from the ECR repository URL.

### ArgoCD Application Manifests

Create ArgoCD Application manifests in your GitOps repository.

Create `kubernetes/application-dev.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app-dev
  namespace: monitoring  # ArgoCD is in monitoring namespace
  annotations:
    argocd-image-updater.argoproj.io/image-list: sample-app=123456789012.dkr.ecr.us-west-2.amazonaws.com/sample-app
    argocd-image-updater.argoproj.io/sample-app.update-strategy: latest
    argocd-image-updater.argoproj.io/sample-app.allow-tags: regexp:^(latest|dev-.*)$
    argocd-image-updater.argoproj.io/write-back-method: git
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/sample-app.git
    targetRevision: main
    path: helm-charts/app-chart
    helm:
      valueFiles:
        - values/dev.yaml
  
  destination:
    server: https://kubernetes.default.svc
    namespace: development
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=false  # Namespace created in Project 2
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

Create `kubernetes/application-prod.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-app-prod
  namespace: monitoring  # ArgoCD is in monitoring namespace
  annotations:
    argocd-image-updater.argoproj.io/image-list: sample-app=123456789012.dkr.ecr.us-west-2.amazonaws.com/sample-app
    argocd-image-updater.argoproj.io/sample-app.update-strategy: semver
    argocd-image-updater.argoproj.io/sample-app.allow-tags: regexp:^v[0-9]+\.[0-9]+\.[0-9]+$
    argocd-image-updater.argoproj.io/write-back-method: git
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/sample-app.git
    targetRevision: main
    path: helm-charts/app-chart
    helm:
      valueFiles:
        - values/prod.yaml
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: false  # Manual sync for production
      allowEmpty: false
    syncOptions:
      - CreateNamespace=false
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

**Important**: Replace `YOUR_USERNAME` and `123456789012` with your values.

### Deploy ArgoCD Applications

```bash
# Apply development application
kubectl apply -f kubernetes/application-dev.yaml

# Apply production application
kubectl apply -f kubernetes/application-prod.yaml

# Check applications
kubectl get applications -n monitoring

# Watch application sync
kubectl get applications -n monitoring -w
```

## Helm Chart Updates

Update the Helm chart deployment template to use the actual container.

### Update templates/deployment.yaml

This should already exist from Project 2. Ensure it includes:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "app-chart.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "app-chart.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "app-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "{{ .Values.metrics.enabled }}"
        prometheus.io/port: "{{ .Values.metrics.port }}"
        prometheus.io/path: "{{ .Values.metrics.path }}"
      labels:
        {{- include "app-chart.selectorLabels" . | nindent 8 }}
    spec:
      securityContext:
        {{- toYaml .Values.securityContext | nindent 8 }}
      
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        
        ports:
        - name: http
          containerPort: {{ .Values.service.targetPort }}
          protocol: TCP
        
        {{- if .Values.livenessProbe }}
        livenessProbe:
          {{- toYaml .Values.livenessProbe | nindent 10 }}
        {{- end }}
        
        {{- if .Values.readinessProbe }}
        readinessProbe:
          {{- toYaml .Values.readinessProbe | nindent 10 }}
        {{- end }}
        
        resources:
          {{- toYaml .Values.resources | nindent 10 }}
        
        securityContext:
          {{- toYaml .Values.containerSecurityContext | nindent 10 }}
        
        {{- if .Values.env }}
        env:
          {{- toYaml .Values.env | nindent 10 }}
        {{- end }}
        
        {{- if .Values.volumeMounts }}
        volumeMounts:
          {{- toYaml .Values.volumeMounts | nindent 10 }}
        {{- end }}
      
      {{- if .Values.volumes }}
      volumes:
        {{- toYaml .Values.volumes | nindent 8 }}
      {{- end }}
      
      {{- if .Values.affinity }}
      affinity:
        {{- toYaml .Values.affinity | nindent 8 }}
      {{- end }}
```

## Deployment Instructions

Now let's deploy everything step-by-step.

### Step 1: Push Application Code to GitHub

```bash
# In your sample-app directory
git add .
git commit -m "Initial sample application with CI/CD"
git push origin main
```

This will trigger the CodeBuild pipeline automatically.

### Step 2: Monitor CodeBuild Execution

```bash
# Watch build status
aws codebuild list-builds-for-project --project-name sample-app-build

# Get latest build ID
BUILD_ID=$(aws codebuild list-builds-for-project \
  --project-name sample-app-build \
  --query 'ids[0]' \
  --output text)

# Watch build progress
aws codebuild batch-get-builds --ids $BUILD_ID \
  --query 'builds[0].{status:buildStatus,phase:currentPhase}' \
  --output table

# Stream logs in real-time
aws logs tail /aws/codebuild/sample-app --follow
```

**Expected build phases**:
1. SUBMITTED → QUEUED → PROVISIONING
2. DOWNLOAD_SOURCE (clone GitHub repo)
3. PRE_BUILD (ECR login, install Trivy)
4. BUILD (Docker build)
5. POST_BUILD (Security scan, push to ECR)
6. COMPLETED

**Build time**: ~5-10 minutes for first build (with caching, subsequent builds ~3-5 minutes)

### Step 3: Verify ECR Image

```bash
# Get ECR repository URI
ECR_REPO=$(terraform output -raw ecr_repository_url)

# List images in ECR
aws ecr list-images --repository-name sample-app

# Describe latest image
aws ecr describe-images \
  --repository-name sample-app \
  --image-ids imageTag=latest

# Get image scan findings
aws ecr describe-image-scan-findings \
  --repository-name sample-app \
  --image-id imageTag=latest
```

**Expected output**: Image with tags `latest`, `<commit-hash>`, and scan findings showing no HIGH/CRITICAL vulnerabilities.

### Step 4: Deploy to Development

ArgoCD should automatically detect the new image and sync to development:

```bash
# Check ArgoCD application status
kubectl get application sample-app-dev -n monitoring

# Watch application sync
kubectl get application sample-app-dev -n monitoring -w

# Force sync if needed
kubectl patch application sample-app-dev -n monitoring \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"manual"},"sync":{"revision":"main"}}}'
```

**Or via ArgoCD CLI**:

```bash
# Install ArgoCD CLI if not already installed
brew install argocd  # macOS
# or download from https://github.com/argoproj/argo-cd/releases

# Port-forward to ArgoCD server
kubectl port-forward svc/argocd-server -n monitoring 8080:443 &

# Login (password from Project 2)
ARGOCD_PASSWORD=$(kubectl -n monitoring get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

# Sync application
argocd app sync sample-app-dev
```

### Step 5: Verify Development Deployment

```bash
# Check pods in development namespace
kubectl get pods -n development

# Check deployment status
kubectl get deployment -n development

# Check service
kubectl get service -n development

# View pod logs
kubectl logs -n development -l app=sample-app --tail=50

# Check pod events
kubectl get events -n development --sort-by='.lastTimestamp'
```

**Expected output**:
```
NAME                          READY   STATUS    RESTARTS   AGE
sample-app-5f7d8c6b9d-abcde   1/1     Running   0          2m
```

### Step 6: Test Application in Development

```bash
# Port-forward to test locally
kubectl port-forward -n development svc/sample-app 3000:80

# In another terminal, test endpoints
curl http://localhost:3000/health
# Expected: {"status":"healthy","timestamp":"..."}

curl http://localhost:3000/ready
# Expected: {"status":"ready","timestamp":"..."}

curl http://localhost:3000/api/items
# Expected: [{"id":1,"name":"Item 1",...},...]

# Test creating an item
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Created via API"}'

# Check Prometheus metrics
curl http://localhost:3000/metrics
# Expected: Prometheus metrics output
```

### Step 7: Deploy to Production

For production, we'll use semantic versioning and manual approval:

```bash
# Tag a release version
git tag -a v1.0.0 -m "First production release"
git push origin v1.0.0

# Update production values to use v1.0.0 tag
# Edit helm-charts/app-chart/values/prod.yaml
# Change: tag: "v1.0.0"

# Commit and push
git add helm-charts/app-chart/values/prod.yaml
git commit -m "Update production to v1.0.0"
git push origin main

# Manually sync production application
argocd app sync sample-app-prod

# Or via kubectl
kubectl patch application sample-app-prod -n monitoring \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"manual"},"sync":{"revision":"main"}}}'
```

### Step 8: Verify Production Deployment

```bash
# Check pods in production namespace
kubectl get pods -n production

# Should see 3 replicas
kubectl get deployment -n production

# Check service (LoadBalancer)
kubectl get service -n production

# Get LoadBalancer external IP (may take 2-3 minutes)
LB_URL=$(kubectl get service sample-app -n production \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo $LB_URL

# Test via LoadBalancer
curl http://$LB_URL/health
curl http://$LB_URL/api/items
```

## Verification

Comprehensive verification of the entire CI/CD pipeline.

### Step 1: Verify ECR Repository

```bash
# Check repository exists
aws ecr describe-repositories --repository-names sample-app

# List all images
aws ecr list-images --repository-name sample-app --output table

# Check lifecycle policy
aws ecr get-lifecycle-policy --repository-name sample-app
```

**Expected**: Repository with multiple image tags and lifecycle policy configured.

### Step 2: Verify CodeBuild Project

```bash
# Check project exists
aws codebuild batch-get-projects --names sample-app-build

# List recent builds
aws codebuild list-builds-for-project --project-name sample-app-build

# Check webhook configuration
aws codebuild list-webhooks --project-name sample-app-build
```

**Expected**: CodeBuild project configured with GitHub webhook.

### Step 3: Verify Image Security

```bash
# Scan image locally with Trivy
docker pull $(terraform output -raw ecr_repository_url):latest
trivy image $(terraform output -raw ecr_repository_url):latest

# Check AWS ECR scan results
aws ecr describe-image-scan-findings \
  --repository-name sample-app \
  --image-id imageTag=latest \
  --query 'imageScanFindings.findingSeverityCounts'
```

**Expected**: No HIGH or CRITICAL vulnerabilities.

### Step 4: Verify ArgoCD Applications

```bash
# Check application health
argocd app get sample-app-dev
argocd app get sample-app-prod

# Check sync status
kubectl get applications -n monitoring

# View application resources
argocd app resources sample-app-dev
```

**Expected output**:
```
NAME              SYNC STATUS   HEALTH STATUS
sample-app-dev    Synced        Healthy
sample-app-prod   Synced        Healthy
```

### Step 5: Verify Pod Security Compliance

```bash
# Check pod security context in development
kubectl get pod -n development -o jsonpath='{.items[0].spec.securityContext}' | jq

# Check container security context
kubectl get pod -n development \
  -o jsonpath='{.items[0].spec.containers[0].securityContext}' | jq

# Verify non-root user
kubectl exec -n development deployment/sample-app -- id
# Expected: uid=65532(nonroot) gid=65532(nonroot)

# Check read-only root filesystem
kubectl exec -n development deployment/sample-app -- touch /test
# Expected: Error (read-only filesystem)
```

### Step 6: Verify Health Checks

```bash
# Check liveness probe
kubectl describe pod -n development -l app=sample-app | grep -A 5 "Liveness"

# Check readiness probe
kubectl describe pod -n development -l app=sample-app | grep -A 5 "Readiness"

# Verify probes are working
kubectl get pods -n development -w
# Pods should remain in Running state with READY 1/1
```

### Step 7: Verify Metrics Endpoint

```bash
# Port-forward to metrics endpoint
kubectl port-forward -n development svc/sample-app 3000:80 &

# Fetch Prometheus metrics
curl -s http://localhost:3000/metrics | grep -E "^http_request_duration|^nodejs_"

# Expected: Prometheus-format metrics output
```

### Step 8: End-to-End Workflow Test

Test the complete CI/CD flow:

```bash
# Make a code change
echo "console.log('Testing CI/CD');" >> src/server.js

# Commit and push
git add src/server.js
git commit -m "Test CI/CD pipeline"
git push origin main

# Monitor build
aws logs tail /aws/codebuild/sample-app --follow

# Wait for ArgoCD to detect and sync (auto-sync enabled for dev)
kubectl get pods -n development -w

# Verify new pod is running
kubectl logs -n development -l app=sample-app --tail=20 | grep "Testing CI/CD"
```

**Expected**: New build triggers, image pushed to ECR, ArgoCD syncs, new pod deployed.

### Verification Checklist

- [ ] ECR repository created with lifecycle policies
- [ ] CodeBuild project configured with webhook
- [ ] First build completed successfully
- [ ] Image pushed to ECR with multiple tags
- [ ] Security scan shows no HIGH/CRITICAL vulnerabilities
- [ ] ArgoCD applications created and healthy
- [ ] Pods running in development namespace
- [ ] Pods running in production namespace (3 replicas)
- [ ] Health checks passing (/health returns 200)
- [ ] Readiness checks passing (/ready returns 200)
- [ ] Metrics endpoint accessible (/metrics)
- [ ] API endpoints functional (/api/items)
- [ ] Pod security contexts configured correctly
- [ ] Non-root user execution verified
- [ ] Read-only root filesystem enforced
- [ ] LoadBalancer service accessible in production
- [ ] End-to-end CI/CD workflow functioning

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: CodeBuild fails to authenticate to ECR

**Symptoms**:
```
Error: denied: Your authorization token has expired
```

**Solution**:
```bash
# Verify CodeBuild IAM role has ECR permissions
aws iam get-role-policy --role-name sample-app-codebuild-role --policy-name sample-app-codebuild-role

# Check if ECR repository exists
aws ecr describe-repositories --repository-names sample-app

# Verify KMS key permissions
aws kms describe-key --key-id alias/ecr-sample-app
```

#### Issue 2: Trivy security scan fails build

**Symptoms**:
```
Security scan found HIGH or CRITICAL vulnerabilities!
Build will fail.
```

**Solution**:

Option 1 - Update base image and rebuild:
```bash
# Pull latest distroless image
docker pull gcr.io/distroless/nodejs20-debian12:nonroot

# Rebuild with latest base
docker build -t sample-app:fixed .

# Scan locally
trivy image sample-app:fixed
```

Option 2 - Temporarily allow vulnerabilities (not recommended):
```yaml
# In buildspec.yml, change:
trivy image --severity HIGH,CRITICAL --exit-code 0 $ECR_REPOSITORY_URI:$IMAGE_TAG
# Note: exit-code 0 means don't fail on vulnerabilities
```

#### Issue 3: ArgoCD application stuck in "Progressing"

**Symptoms**:
```
HEALTH STATUS   MESSAGE
Progressing     Waiting for rollout to finish: 0 of 1 updated replicas are available
```

**Solution**:
```bash
# Check pod status
kubectl get pods -n development

# Check pod events
kubectl describe pod -n development -l app=sample-app

# Common causes:
# 1. Image pull error
kubectl describe pod -n development -l app=sample-app | grep -A 10 "Events"

# 2. Health check failing
kubectl logs -n development -l app=sample-app

# 3. Resource quota exceeded
kubectl describe resourcequota -n development
```

#### Issue 4: Pod fails with "readOnlyRootFilesystem" error

**Symptoms**:
```
Error: EACCES: permission denied, open '/app/some-file'
```

**Solution**:

The application is trying to write to the filesystem. Add volume mounts:

```yaml
# In values.yaml, ensure:
volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}

volumeMounts:
  - name: tmp
    mountPath: /tmp
  - name: cache
    mountPath: /app/.npm
```

#### Issue 5: Cannot connect to LoadBalancer in production

**Symptoms**:
```
curl: (7) Failed to connect to <hostname> port 80: Connection refused
```

**Solution**:
```bash
# Check service type
kubectl get service sample-app -n production

# Check if LoadBalancer is provisioned
kubectl describe service sample-app -n production

# Verify security group allows traffic
# Get worker node security group
kubectl get nodes -o wide

# Check AWS Load Balancer Controller logs (if installed)
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify pod is listening on correct port
kubectl exec -n production deployment/sample-app -- netstat -tuln
```

#### Issue 6: High memory usage / OOMKilled

**Symptoms**:
```
NAME                          READY   STATUS      RESTARTS   AGE
sample-app-5f7d8c6b9d-abcde   0/1     OOMKilled   3          5m
```

**Solution**:
```bash
# Check current resource usage
kubectl top pods -n production

# Increase memory limits in values/prod.yaml
resources:
  limits:
    memory: 1Gi  # Increase from 512Mi
  requests:
    memory: 512Mi

# Apply changes
git commit -am "Increase memory limits"
git push origin main
```

### Getting Help

If issues persist:

1. **Check application logs**:
   ```bash
   kubectl logs -n development -l app=sample-app --tail=100
   ```

2. **Check CodeBuild logs**:
   ```bash
   aws logs tail /aws/codebuild/sample-app --follow
   ```

3. **Check ArgoCD logs**:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=argocd-application-controller
   ```

4. **Describe resources**:
   ```bash
   kubectl describe pod -n development -l app=sample-app
   kubectl describe deployment -n development sample-app
   ```

## Cleanup

### Step 1: Remove ArgoCD Applications

```bash
# Delete applications
kubectl delete -f kubernetes/application-dev.yaml
kubectl delete -f kubernetes/application-prod.yaml

# Or via ArgoCD CLI
argocd app delete sample-app-dev --yes
argocd app delete sample-app-prod --yes
```

### Step 2: Destroy Terraform Infrastructure

```bash
cd terraform

# Preview what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Type 'yes' when prompted
```

**Time estimate**: 5-10 minutes

### Step 3: Clean Up Local Docker Images

```bash
# Remove local images
docker rmi sample-app:local
docker rmi $(terraform output -raw ecr_repository_url):latest

# Clean up Docker system
docker system prune -a
```

### Step 4: Verify Cleanup

```bash
# Verify ECR repository deleted
aws ecr describe-repositories --repository-names sample-app
# Expected: RepositoryNotFoundException

# Verify CodeBuild project deleted
aws codebuild batch-get-projects --names sample-app-build
# Expected: Empty results

# Verify no pods running
kubectl get pods -n development -l app=sample-app
kubectl get pods -n production -l app=sample-app
# Expected: No resources found
```

## Cost Considerations

### Estimated AWS Costs

| Resource | Cost | Notes |
|----------|------|-------|
| ECR Storage | $0.10/GB/month | ~100-200MB per image |
| ECR Data Transfer | $0.09/GB | First 1GB free |
| CodeBuild | $0.005/min | Standard Linux small compute |
| CloudWatch Logs | $0.50/GB | Log ingestion |
| KMS Key | $1/month | For ECR encryption |
| S3 Cache Bucket | $0.023/GB/month | Build cache storage |
| **Estimated Total** | **~$5-10/month** | With moderate usage |

### Additional Costs from Projects 1 & 2

- EKS Control Plane: $0.10/hour (~$73/month)
- EC2 Nodes: 2 × t3.medium = ~$60/month
- LoadBalancer (if used in prod): ~$18/month
- **Combined Projects 1-3**: **~$150-170/month**

### Cost Optimization Tips

1. **Use build caching**:
   - Already configured in buildspec.yml
   - Reduces build time and costs

2. **Limit build minutes**:
   ```bash
   # Set build timeout in codebuild.tf
   build_timeout = 15  # minutes instead of 30
   ```

3. **Clean up old images**:
   - Lifecycle policy already configured
   - Keeps last 10 prod + 5 dev images

4. **Reduce log retention**:
   ```hcl
   # In codebuild.tf
   retention_in_days = 3  # instead of 7
   ```

5. **Stop builds when not needed**:
   ```bash
   # Disable webhook temporarily
   aws codebuild delete-webhook --project-name sample-app-build
   ```

## Next Steps

**Congratulations!** 🎉 You now have a fully automated CI/CD pipeline deploying applications to EKS.

### What You Accomplished

- ✅ Created a production-ready Node.js REST API
- ✅ Built secure Docker containers with distroless images
- ✅ Set up ECR with security scanning and lifecycle policies
- ✅ Configured CodeBuild CI/CD pipeline with automated tests
- ✅ Integrated security scanning with Trivy
- ✅ Connected pipeline to ArgoCD GitOps workflow
- ✅ Deployed to both development and production environments
- ✅ Implemented zero-downtime rolling updates

### Project 4 Preview

In the next project, you'll add comprehensive monitoring:
- **Prometheus** for metrics collection
- **Grafana** for visualization and dashboards
- **Alertmanager** for alert routing and notifications
- **ServiceMonitors** for automatic metrics discovery
- **Custom dashboards** for application and infrastructure monitoring
- **Alert rules** for proactive incident detection

Your sample application is already exposing metrics at `/metrics`, ready for Prometheus to scrape!

**Ready to continue?** → Proceed to **Project 4 - Monitoring Stack (Prometheus + Grafana)**

### Additional Learning Resources

- **Docker Multi-Stage Builds**: https://docs.docker.com/build/building/multi-stage/
- **AWS CodeBuild**: https://docs.aws.amazon.com/codebuild/
- **Trivy Security Scanner**: https://aquasecurity.github.io/trivy/
- **ArgoCD Best Practices**: https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/
- **Node.js Security Best Practices**: https://github.com/goldbergyoni/nodebestpractices

---

**Document Version**: 1.0  
**Last Updated**: September 2025  
**Dependencies**: Project 1 (EKS), Project 2 (Helm/ArgoCD)  
**Next Project**: Project 4 - Monitoring Stack
