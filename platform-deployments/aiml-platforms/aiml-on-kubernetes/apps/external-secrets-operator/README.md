# External Secrets Operator Configuration

This directory contains cluster-wide configuration for the External Secrets Operator (ESO).

## Files

| File | Purpose |
|------|---------|
| `cluster-secret-store.yaml` | ClusterSecretStore that connects ESO to AWS Secrets Manager |

## ClusterSecretStore

The `cluster-secret-store.yaml` file creates a cluster-wide resource named `aws-secrets-manager` that:
- Configures AWS Secrets Manager as the secret backend
- Uses IRSA (IAM Roles for Service Accounts) for authentication
- Allows ExternalSecrets in any namespace to reference it

### Deployment

```bash
# Apply the ClusterSecretStore
kubectl apply -f apps/external-secrets-operator/cluster-secret-store.yaml

# Verify it's created
kubectl get clustersecretstore aws-secrets-manager

# Check status (should show Ready: True)
kubectl describe clustersecretstore aws-secrets-manager
```

### Configuration

**Region**: Update the `region` field in the manifest to match your AWS region:

```yaml
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1  # <-- Change this to your region
```

### Troubleshooting

If the ClusterSecretStore shows as not ready:

1. **Check IRSA is configured:**
   ```bash
   kubectl get sa external-secrets-sa -n external-secrets -o yaml | grep eks.amazonaws.com/role-arn
   ```
   Expected: You should see an annotation with an IAM role ARN

2. **Check ESO pods are running:**
   ```bash
   kubectl get pods -n external-secrets
   ```
   Expected: All pods should be in Running state

3. **Check ESO logs for errors:**
   ```bash
   kubectl logs -n external-secrets deployment/external-secrets --tail=50
   ```

4. **Verify IAM role has Secrets Manager permissions:**
   ```bash
   # Get the role name from the annotation above
   aws iam get-role --role-name <role-name-from-annotation>
   aws iam list-attached-role-policies --role-name <role-name-from-annotation>
   ```
   Expected: Should have a policy that grants `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret`

5. **Check region matches where secrets are stored:**
   ```bash
   # List secrets in your region
   aws secretsmanager list-secrets --region us-east-1 | grep aiml-platform
   ```
   If your secrets are in a different region, update the `region` field in the manifest.

## How It Works

The ClusterSecretStore acts as a bridge between Kubernetes and AWS Secrets Manager:

```
AWS Secrets Manager
        ↓ (IRSA authentication)
ClusterSecretStore (aws-secrets-manager)
        ↓
ExternalSecret Resources
        ↓
Kubernetes Secrets (auto-created/updated)
        ↓
Application Pods
```

**IRSA (IAM Roles for Service Accounts)** allows the External Secrets Operator pod to authenticate to AWS without storing credentials. The pod assumes an IAM role via the EKS cluster's OIDC provider.

## Related Documentation

- [Main README](../../README.md) - Overall platform documentation
- [Secret Management Guide](../../docs/secret-management.md) - Comprehensive ESO documentation
- [External Secrets Operator Docs](https://external-secrets.io) - Official ESO documentation
