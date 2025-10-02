# AWS Secrets Manager Integration Guide

This guide explains how AWS Secrets Manager is integrated into this EKS DevOps project, from Terraform creation to secure use in the Kubernetes cluster.

## Overview

AWS Secrets Manager provides secure storage and rotation of secrets. In this project, it's used to store application configuration secrets that are securely injected into Kubernetes pods via the External Secrets Operator.

## Architecture Flow

```
Terraform → AWS Secrets Manager → External Secrets Operator → Kubernetes Secrets → Pods
```

## 1. Terraform Creation (Project 1)

### Secret Resources Created

The `secrets-manager.tf` file creates two secrets:

```terraform
# Development environment secret
resource "aws_secretsmanager_secret" "dev_app_config" {
  name        = "dev/app/config"
  description = "Development application configuration"
  recovery_window_in_days = 0  # Immediate deletion for dev/test
}

# Production environment secret
resource "aws_secretsmanager_secret" "prod_app_config" {
  name        = "prod/app/config"
  description = "Production application configuration"
  recovery_window_in_days = 7  # 7-day recovery window for production
}
```

### IAM Permissions

Terraform also creates the necessary IAM roles and policies:

- **IAM Policy**: Grants read access to the specific secrets
- **IAM Role**: Uses IRSA (IAM Roles for Service Accounts) for the External Secrets Operator
- **OIDC Provider**: Links the EKS cluster to AWS IAM

## 2. Secret Value Population

### Manual Secret Population

After Terraform creates the empty secret containers, you manually populate them with real values when your application needs them:

```bash
# Add real secrets when your application needs them
aws secretsmanager put-secret-value \
  --secret-id "dev/app/config" \
  --secret-string '{
    "DATABASE_URL": "postgresql://real-db-host:5432/real-database",
    "API_KEY": "real-api-key-from-your-service",
    "JWT_SECRET": "your-actual-jwt-secret",
    "REDIS_URL": "redis://real-redis-host:6379"
  }'
```

**Note**: Secrets start empty and are populated manually when needed. This ensures no placeholder or test values are accidentally used in production.

## 3. What Happens with Empty Secrets

### Initial State (Empty Secrets)

When External Secrets Operator first tries to sync from empty secrets:

```bash
# Check ExternalSecret status (will show error initially)
kubectl get externalsecret app-config -n development
# Status: SecretSyncedError

# Check error details
kubectl describe externalsecret app-config -n development
# Error: Secret not found or empty
```

### After Adding Real Secrets

Once you populate the secrets with real values:

```bash
# External Secrets Operator automatically detects the change
kubectl get externalsecret app-config -n development
# Status: SecretSynced

# Kubernetes secret is created
kubectl get secret app-config -n development
# Shows the synced secret
```

## 4. External Secrets Operator Integration (Project 2)

### SecretStore Configuration

The External Secrets Operator needs a SecretStore to connect to AWS:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: monitoring
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
```

### ExternalSecret Resources

Create ExternalSecret resources to sync secrets from AWS to Kubernetes:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config-dev
  namespace: development
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: app-config
    creationPolicy: Owner
  data:
  - secretKey: database_url
    remoteRef:
      key: dev/app/config
      property: database_url
  - secretKey: api_key
    remoteRef:
      key: dev/app/config
      property: api_key
```

## 4. Secure Use in Kubernetes

### Pod Configuration

Applications consume secrets as environment variables or mounted files:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: your-app:latest
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-config
              key: database_url
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-config
              key: api_key
```

### Security Benefits

1. **No hardcoded secrets** in container images or manifests
2. **Automatic rotation** support (when configured)
3. **Audit logging** of secret access
4. **Fine-grained permissions** via IAM
5. **Encryption at rest** and in transit

## 5. Environment-Specific Configuration

### Development Environment
- **Secret Name**: `dev/app/config`
- **Recovery Window**: 0 days (immediate deletion)
- **Namespace**: `development`
- **Refresh Interval**: 1 hour

### Production Environment
- **Secret Name**: `prod/app/config`
- **Recovery Window**: 7 days
- **Namespace**: `production`
- **Refresh Interval**: 15 minutes

## 6. Best Practices

### Secret Management
- ✅ Use descriptive secret names with environment prefixes
- ✅ Store structured data as JSON
- ✅ Set appropriate recovery windows
- ✅ Enable automatic rotation for sensitive secrets
- ❌ Never commit secret values to version control
- ❌ Don't use default recovery windows in production

### Access Control
- ✅ Use IRSA for pod-level permissions
- ✅ Implement least-privilege IAM policies
- ✅ Regularly audit secret access
- ✅ Use separate secrets for different environments

### Monitoring
- ✅ Monitor secret access via CloudTrail
- ✅ Set up alerts for failed secret retrievals
- ✅ Track External Secrets Operator sync status
- ✅ Monitor secret rotation events

## 7. Troubleshooting

### Common Issues

**Secret not found:**
```bash
# Check if secret exists
aws secretsmanager describe-secret --secret-id dev/app/config

# If secret exists but is empty, populate it with real values
aws secretsmanager put-secret-value \
  --secret-id "dev/app/config" \
  --secret-string '{"DATABASE_URL": "your-real-db-url", "API_KEY": "your-real-api-key"}'
```

**External Secrets not syncing:**
```bash
# Check External Secrets Operator logs
kubectl logs -n monitoring deployment/external-secrets

# Verify SecretStore status
kubectl describe secretstore aws-secrets-manager -n monitoring

# Check ExternalSecret status
kubectl describe externalsecret app-config-dev -n development
```

**Permission denied:**
```bash
# Verify IRSA configuration
kubectl describe serviceaccount external-secrets -n monitoring

# Check IAM role trust policy
aws iam get-role --role-name eks-cluster-external-secrets
```

## 8. Next Steps

1. **Deploy External Secrets Operator** (Project 2)
2. **Configure SecretStore** with proper IAM permissions
3. **Create ExternalSecret resources** for each environment
4. **Populate secrets with real values** when your applications need them
5. **Update application deployments** to use Kubernetes secrets
6. **Set up monitoring and alerting** for secret access

## 9. Security Considerations

- **Network Security**: Secrets are transmitted over HTTPS
- **Encryption**: All secrets are encrypted at rest using AWS KMS
- **Access Logging**: All secret access is logged in CloudTrail
- **Rotation**: Implement automatic rotation for long-lived secrets
- **Backup**: Secrets are automatically backed up by AWS

This integration provides a secure, scalable way to manage application secrets across your EKS cluster while maintaining separation between development and production environments.
