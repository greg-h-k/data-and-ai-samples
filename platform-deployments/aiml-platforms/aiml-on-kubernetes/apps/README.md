# Application Configurations

This directory contains Helm values files and Kubernetes manifests for deploying AI/ML applications on the EKS cluster.

## Directory Structure

```
apps/
├── README.md                     # This file
├── bootstrap.example.yaml        # ArgoCD app definitions (requires Git repo setup)
├── external-secrets-operator/    # ClusterSecretStore for AWS Secrets Manager
├── datahub/                      # Data catalog and governance
├── datahub-pre/                  # DataHub prerequisites (MySQL, Neo4j, Kafka, ES)
├── langflow-ide/                 # Visual AI workflow builder
├── langfuse/                     # LLM observability and tracing
├── monitoring/                   # Prometheus + Grafana stack
└── vllm/                         # LLM inference server
```

## Using Values Files

Each application directory contains:

| File | Purpose | Git Tracked |
|------|---------|-------------|
| `values.example.yaml` | Template with placeholders | ✅ Yes |
| `values.yaml` | Your actual configuration | ❌ No (gitignored) |
| `external-secret.yaml` | Secret sync from AWS Secrets Manager | ✅ Yes |

### First-Time Setup

1. **Copy the example file:**
   ```bash
   cd apps/<application>/
   cp values.example.yaml values.yaml
   ```

2. **Update placeholder values:**
   ```bash
   # Edit values.yaml with your actual configuration
   vim values.yaml

   # Common values to update:
   # - ingress.hosts[].host: Your actual domain (e.g., langflow.example.com)
   # - ingress.annotations.alb.ingress.kubernetes.io/certificate-arn: Your ACM cert ARN
   # - Any other application-specific settings
   ```

3. **Deploy with Helm:**
   ```bash
   helm install <app-name> <chart> \
     --repo <chart-repo-url> \
     --version <version> \
     --values apps/<application>/values.yaml \
     --namespace <namespace> --create-namespace
   ```

### What to Update

**Required changes:**
- **Domain names:** Update `ingress.hosts[].host` with your actual domain
- **Certificates:** Add your ACM certificate ARN for HTTPS

**Optional changes:**
- **Resource limits:** Adjust CPU/memory based on your needs
- **Replica counts:** Scale up/down based on load
- **Storage:** Configure PVC sizes and storage classes
- **Feature flags:** Enable/disable application features

### Example: Langflow IDE

```bash
# 1. Copy example
cp apps/langflow-ide/values.example.yaml apps/langflow-ide/values.yaml

# 2. Edit and update the host
vim apps/langflow-ide/values.yaml
# Change: langflow-ide.example.com
# To: langflow-ide.yourdomain.com

# 3. Deploy
helm install langflow-ide langflow-ide \
  --repo https://langflow-ai.github.io/langflow-helm-charts \
  --version 0.1.1 \
  --values apps/langflow-ide/values.yaml \
  --namespace langflow-ide --create-namespace
```

## Ingress Configuration

All applications use AWS Application Load Balancer (ALB) for ingress. EKS Auto Mode provides built-in ALB support without requiring the AWS Load Balancer Controller.

### Basic Ingress Setup

```yaml
ingress:
  enabled: true
  ingressClassName: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/xxx
  hosts:
    - host: app.your-domain.com
      paths:
        - path: /
          pathType: Prefix
```

### Shared Load Balancer (Cost Optimization)

To share a single ALB across multiple applications, uncomment the `group.name` annotation:

```yaml
annotations:
  alb.ingress.kubernetes.io/group.name: aiml-platform-ingress  # All apps with same name share ALB
  alb.ingress.kubernetes.io/scheme: internet-facing
  # ... other annotations
```

**Benefits:**
- **Cost savings:** Single ALB (~$16/month) instead of one per app
- **Simplified DNS:** One ALB endpoint for all applications
- **Consistent configuration:** Shared security groups and settings

## Secret Management

Secrets are managed via External Secrets Operator (ESO) which syncs from AWS Secrets Manager.

### How It Works

```
AWS Secrets Manager → ClusterSecretStore → ExternalSecret → Kubernetes Secret → Application
```

### Setting Up Secrets

1. **Generate and upload secrets to AWS:**
   ```bash
   cd ../..  # Back to aiml-on-kubernetes/
   ./generate-and-upload-secrets.sh
   ```

2. **Apply ExternalSecret resources:**
   ```bash
   kubectl apply -f apps/langfuse/external-secret.yaml
   kubectl apply -f apps/datahub-pre/mysql-external-secret.yaml
   kubectl apply -f apps/datahub-pre/neo4j-external-secret.yaml
   kubectl apply -f apps/monitoring/grafana-external-secret.yaml
   ```

3. **Verify secrets synced:**
   ```bash
   kubectl get externalsecrets -A
   kubectl get secrets -n langfuse
   ```

See [Secret Management Guide](../docs/secret-management.md) for details.

## GitOps with ArgoCD

For automated deployment using GitOps:

1. **Update bootstrap.yaml with your Git repository:**
   ```bash
   cp bootstrap.example.yaml bootstrap.yaml
   vim bootstrap.yaml
   # Update all repoURL fields with your Git repo URL
   ```

2. **Apply ArgoCD applications:**
   ```bash
   kubectl apply -f bootstrap.yaml
   ```

3. **ArgoCD will automatically sync applications from Git**

See main [README](../README.md#step-7-deploy-applications-with-argocd) for details.

## Application Quick Reference

| Application | Port | Purpose | Docs |
|-------------|------|---------|------|
| **vLLM** | 8000 | LLM inference server with OpenAI-compatible API | [vLLM docs](https://docs.vllm.ai/) |
| **Langfuse** | 3000 | LLM observability, tracing, and analytics | [Langfuse docs](https://langfuse.com/docs) |
| **Langflow IDE** | 7860 | Visual workflow builder for AI pipelines | [Langflow docs](https://docs.langflow.org/) |
| **DataHub** | 9002 | Data catalog and metadata management | [DataHub docs](https://datahubproject.io/docs/) |
| **Grafana** | 3000 | Observability dashboards | [Grafana docs](https://grafana.com/docs/) |
| **Prometheus** | 9090 | Metrics collection | [Prometheus docs](https://prometheus.io/docs/) |

## Troubleshooting

### Values File Issues

**Problem:** Helm deployment fails with "values don't meet the specifications of the schema"

**Solution:** Compare your `values.yaml` with `values.example.yaml` to ensure all required fields are present.

### Ingress Not Creating Load Balancer

**Problem:** `kubectl get ingress` shows no ADDRESS

**Solutions:**
1. Check ingress is enabled: `grep "enabled:" apps/<app>/values.yaml`
2. Verify ingress class: `kubectl get ingressclass`
3. See [EKS Auto Mode Ingress Guide](../docs/eks-auto-mode-ingress.md)

### Secret Sync Issues

**Problem:** ExternalSecret shows "SecretSyncedError"

**Solutions:**
1. Check ClusterSecretStore: `kubectl get clustersecretstore aws-secrets-manager`
2. Verify secrets exist in AWS: `aws secretsmanager list-secrets | grep aiml-platform`
3. See [Secret Management Troubleshooting](../docs/secret-management.md#troubleshooting)

## Best Practices

1. **Never commit values.yaml** - It contains your actual configuration and may include sensitive references
2. **Keep values.example.yaml updated** - When adding new configuration, update the example file
3. **Use shared ALB** - Uncomment `group.name` annotation to save costs
4. **Test locally first** - Use `helm template` to preview manifests before deploying
5. **Version control** - Pin Helm chart versions in your actual deployments for stability

## References

- [Main README](../README.md) - Overall platform documentation
- [Secret Management](../docs/secret-management.md) - Detailed ESO guide
- [EKS Auto Mode Ingress](../docs/eks-auto-mode-ingress.md) - Load balancer troubleshooting
- [Helm Documentation](https://helm.sh/docs/) - Helm usage guide
