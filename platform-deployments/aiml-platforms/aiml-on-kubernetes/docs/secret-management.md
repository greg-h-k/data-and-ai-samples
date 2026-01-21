# Secret Management with AWS Secrets Manager and External Secrets Operator

## Overview

This platform uses **External Secrets Operator (ESO)** to sync secrets from AWS Secrets Manager to Kubernetes, eliminating manual secret handling and enabling GitOps-friendly secret management.

## Architecture Components

### 1. AWS Secrets Manager
- Central storage for all sensitive values
- Encrypted at rest with AWS KMS
- Supports automatic rotation
- Full audit trail via CloudTrail
- **Naming convention**: `aiml-platform/{app}/{secret-key}`

### 2. External Secrets Operator (ESO)
- Kubernetes operator running in `external-secrets` namespace
- Authenticates to AWS using IRSA (IAM Roles for Service Accounts)
- Watches ExternalSecret CRDs
- Creates/updates Kubernetes Secrets automatically
- Refresh interval: 1 hour (configurable)

### 3. ClusterSecretStore
- Cluster-wide configuration for AWS Secrets Manager backend
- Single IRSA role for all applications
- Named: `aws-secrets-manager`
- Provides AWS authentication context for ExternalSecrets

### 4. ExternalSecret Resources
- Per-application CRDs that map AWS secrets to Kubernetes secrets
- Define which keys to fetch and how to map them
- Automatic refresh every hour
- Status tracking (SecretSynced, SecretSyncedError, etc.)

## Initial Setup

### Creating the ClusterSecretStore

The ClusterSecretStore must be created once after the EKS cluster is deployed. This is a cluster-wide resource that all ExternalSecrets reference.

**Automatic creation** (included in deploy.sh):

The deployment script automatically creates the ClusterSecretStore. No manual action needed if using `./deploy.sh`.

**Manual creation** (if needed):

```bash
# Apply the ClusterSecretStore manifest
kubectl apply -f apps/external-secrets-operator/cluster-secret-store.yaml

# Verify it's created and ready
kubectl get clustersecretstore aws-secrets-manager

# Expected output:
# NAME                  AGE   STATUS   CAPABILITIES   READY
# aws-secrets-manager   5s    Valid    ReadWrite      True

# Check detailed status
kubectl describe clustersecretstore aws-secrets-manager

# Expected to see:
# Status:
#   Conditions:
#     Status:  True
#     Type:    Ready
```

**Verify IRSA is configured correctly:**

```bash
# Check service account has IAM role annotation
kubectl get sa external-secrets-sa -n external-secrets -o yaml

# Should see:
#   annotations:
#     eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME
```

**Region configuration:**

The ClusterSecretStore is configured to use `us-east-1` by default. If your secrets are in a different region, update the manifest before applying:

```yaml
# apps/external-secrets-operator/cluster-secret-store.yaml
spec:
  provider:
    aws:
      service: SecretsManager
      region: YOUR_REGION  # Change this to your AWS region
```

## Secret Inventory

| Application | AWS Secret Path | Kubernetes Secret | Namespace | Keys |
|-------------|----------------|-------------------|-----------|------|
| **Langfuse** | `aiml-platform/langfuse/*` | `langfuse` | langfuse | 8 keys: salt, encryption-key, nextauth-secret, postgresql-password, clickhouse-password, redis-password, s3-user, s3-password |
| **DataHub MySQL** | `aiml-platform/datahub/mysql-root-password` | `mysql-secrets` | datahub | 1 key: mysql-root-password |
| **DataHub Neo4j** | `aiml-platform/datahub/neo4j-password` | `neo4j-secrets` | datahub | 1 key: neo4j-password |
| **Grafana** | `aiml-platform/monitoring/grafana-admin-password` | `grafana-admin-credentials` | monitoring | 2 keys: admin-user, admin-password |

## Common Operations

### Viewing Secret Values

**From AWS Secrets Manager:**
```bash
# View a specific secret
aws secretsmanager get-secret-value \
  --secret-id aiml-platform/langfuse/salt \
  --region us-east-1 \
  --query SecretString \
  --output text

# List all platform secrets
aws secretsmanager list-secrets \
  --filters Key=name,Values=aiml-platform/ \
  --region us-east-1 \
  --output table
```

**From Kubernetes (base64 encoded):**
```bash
# View encoded value
kubectl get secret langfuse -n langfuse -o jsonpath='{.data.salt}'

# View decoded value
kubectl get secret langfuse -n langfuse -o jsonpath='{.data.salt}' | base64 -d

# View all keys in a secret
kubectl get secret langfuse -n langfuse -o jsonpath='{.data}' | jq 'keys'
```

### Updating a Secret

**1. Update in AWS Secrets Manager:**
```bash
aws secretsmanager update-secret \
  --secret-id aiml-platform/langfuse/postgresql-password \
  --secret-string 'NEW_SECURE_PASSWORD' \
  --region us-east-1
```

**2. Trigger immediate sync (optional, otherwise waits up to 1 hour):**
```bash
# Force sync by updating annotation
kubectl annotate externalsecret langfuse -n langfuse \
  force-sync=$(date +%s) --overwrite

# Watch sync status
kubectl get externalsecret langfuse -n langfuse -w
```

**3. Verify secret updated in Kubernetes:**
```bash
# Check if Kubernetes secret has new value
kubectl get secret langfuse -n langfuse -o jsonpath='{.data.postgresql-password}' | base64 -d
```

**4. Restart application pods to use new secret:**
```bash
# Restart all deployments in namespace
kubectl rollout restart deployment -n langfuse

# Or restart specific deployment
kubectl rollout restart deployment/langfuse-web -n langfuse

# Check rollout status
kubectl rollout status deployment/langfuse-web -n langfuse
```

## References

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [EKS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Kubernetes Secrets Best Practices](https://kubernetes.io/docs/concepts/security/secrets-good-practices/)
