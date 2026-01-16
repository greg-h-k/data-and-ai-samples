# AI/ML Platform on Amazon EKS

> **Services:** Amazon EKS, Amazon VPC, Amazon Route 53, Amazon ACM, Amazon ECR, ArgoCD, Prometheus, Grafana
> **Complexity:** Advanced
> **Last Updated:** 2026-01-16

Production-ready AI/ML platform on Amazon EKS with GPU support, automated GitOps deployment via ArgoCD, and integrated observability stack.

## ⚠️ Important Security Notice

**This is a demonstration deployment for development and testing purposes.**

Before deploying to production environments, you must:
- Remove all placeholder credentials and generate strong secrets
- Update all domain names and AWS account-specific values in configuration files
- Review and harden security group rules for least-privilege access
- Enable CloudTrail and VPC Flow Logs for audit trails
- Implement proper backup and disaster recovery procedures
- Configure RBAC for Kubernetes and ArgoCD with principle of least privilege
- Use AWS Secrets Manager or External Secrets Operator for secret management
- Enable EKS audit logging and review logs regularly
- Restrict EKS API endpoint access to specific IP ranges
- Implement Pod Security Standards (PSS/PSA)
- Configure Network Policies to restrict pod-to-pod communication
- Enable container image scanning in ECR
- Review [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)

**DO NOT use example passwords or configurations shown in this demo in production.**

## Overview

### What This Platform Provides

This platform deploys a complete AI/ML infrastructure on Kubernetes, suitable for LLM inference, model serving, data observability, and team collaboration on ML workloads.

**Core Infrastructure:**
- **Amazon EKS** with EKS Auto Mode - Managed Kubernetes cluster with automatic compute provisioning
- **GPU Node Pool** - g4dn instances with NVIDIA T4 GPUs for model inference workloads
- **Application Load Balancer** - Automatic ingress with SSL/TLS termination via AWS Load Balancer Controller
- **VPC with 3 Availability Zones** - High availability network architecture with public and private subnets
- **ArgoCD** - GitOps continuous deployment for declarative application management

**AI/ML Applications** (optional, can be enabled/disabled individually):
- **vLLM** - High-performance LLM inference serving with OpenAI-compatible API
- **Langfuse** - LLM observability and analytics for tracking prompts, costs, and performance
- **LibreChat** - Multi-model AI chat interface supporting OpenAI, Azure, Anthropic, and custom endpoints
- **Langflow IDE** - Visual LLM workflow builder for creating RAG pipelines and AI agents
- **DataHub** - Data discovery and metadata catalog for data governance

**Observability Stack:**
- **Prometheus** - Metrics collection and alerting for all services
- **Grafana** - Visualization and pre-configured dashboards for Kubernetes and vLLM
- **Prometheus Adapter** - Custom metrics for Horizontal Pod Autoscaling (HPA)

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                           AWS Account                                │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  VPC (10.2.0.0/16) - 3 Availability Zones                      │ │
│  │                                                                  │ │
│  │  ┌──────────────────────────────────────────────────────────┐  │ │
│  │  │ Public Subnets                                            │  │ │
│  │  │ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │  │ │
│  │  │ │  ALB (443)   │ │  NAT Gateway │ │  NAT Gateway │      │  │ │
│  │  │ │  (ArgoCD,    │ │   (AZ-1)     │ │   (AZ-2)     │      │  │ │
│  │  │ │   Apps)      │ └──────────────┘ └──────────────┘      │  │ │
│  │  │ └──────────────┘                                          │  │ │
│  │  └────────────────────────┬─────────────────────────────────┘  │ │
│  │                           │                                     │ │
│  │                           ▼                                     │ │
│  │  ┌──────────────────────────────────────────────────────────┐  │ │
│  │  │ Private Subnets - EKS Worker Nodes                        │  │ │
│  │  │                                                            │  │ │
│  │  │ ┌────────────────────────────────────────────────────┐   │  │ │
│  │  │ │ EKS Cluster (Auto Mode)                            │   │  │ │
│  │  │ │                                                     │   │  │ │
│  │  │ │  ┌───────────────────┐  ┌────────────────────┐    │   │  │ │
│  │  │ │  │ GPU Node Pool     │  │  General Purpose   │    │   │  │ │
│  │  │ │  │ (g4dn family)     │  │  Node Pool         │    │   │  │ │
│  │  │ │  │ - vLLM            │  │  - ArgoCD          │    │   │  │ │
│  │  │ │  │ - ML workloads    │  │  - Monitoring      │    │   │  │ │
│  │  │ │  └───────────────────┘  │  - Applications    │    │   │  │ │
│  │  │ │                          └────────────────────┘    │   │  │ │
│  │  │ │                                                     │   │  │ │
│  │  │ │  Namespaces:                                       │   │  │ │
│  │  │ │  - argocd (GitOps deployment)                     │   │  │ │
│  │  │ │  - monitoring (Prometheus/Grafana)                │   │  │ │
│  │  │ │  - vllm (LLM inference serving)                   │   │  │ │
│  │  │ │  - langfuse (LLM observability)                   │   │  │ │
│  │  │ │  - librechat (Chat interface)                     │   │  │ │
│  │  │ │  - langflow-ide (Workflow builder)                │   │  │ │
│  │  │ │  - datahub (Data catalog)                         │   │  │ │
│  │  │ └─────────────────────────────────────────────────────┘   │  │ │
│  │  └──────────────────────────────────────────────────────────┘  │ │
│  │                                                                  │ │
│  │  VPC Endpoints: S3, ECR, EC2Messages, SSM, SSMMessages         │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  Route 53 DNS                                                   │ │
│  │  - argocd.your-domain.com → ALB                                │ │
│  │  - langfuse.your-domain.com → ALB                              │ │
│  │  - chat.your-domain.com → ALB                                  │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### AWS Requirements

1. **AWS Account** with permissions to create:
   - VPC, subnets, NAT gateways, Internet gateways, Application Load Balancers
   - EKS clusters (with EKS Auto Mode enabled in your region)
   - IAM roles, policies, and OIDC providers
   - Route 53 hosted zones and DNS records
   - ACM certificates for SSL/TLS
   - ECR repositories for container images

2. **ACM Certificate** in target region:
   - Must cover your domain (wildcard recommended: `*.your-domain.com`)
   - Must be validated (DNS or email validation) before deployment
   - Certificate ARN will be needed for `terraform.tfvars`

3. **Route 53 Hosted Zone**:
   - Public hosted zone for your domain
   - Note the Zone ID (visible in Route 53 console) - needed for `terraform.tfvars`
   - Ensure NS records are properly delegated if using subdomain

4. **IAM Admin Role**:
   - Role with AdministratorAccess or equivalent permissions
   - Note the ARN (format: `arn:aws:iam::ACCOUNT_ID:role/RoleName`)
   - This role will have admin access to the EKS cluster

### Local Tools

Install the following tools on your workstation:

- **AWS CLI** 2.x configured with credentials ([installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
  - Configure with: `aws configure`
  - Verify with: `aws sts get-caller-identity`
- **Terraform** 1.5+ ([installation guide](https://www.terraform.io/downloads))
  - Verify with: `terraform version`
- **kubectl** 1.28+ ([installation guide](https://kubernetes.io/docs/tasks/tools/))
  - Verify with: `kubectl version --client`
- **Helm** 3.x ([installation guide](https://helm.sh/docs/intro/install/))
  - Verify with: `helm version`
- **OpenSSL** - For generating secrets (pre-installed on most systems)
  - Verify with: `openssl version`

### Before Deployment

**Critical steps you MUST complete before running `./deploy.sh`:**

1. **Update terraform.tfvars** with your AWS account values:
   ```bash
   cd terraform/environments/dev
   vim terraform.tfvars
   ```
   Update:
   - AWS region
   - IAM admin role ARN (your account ID and role name)
   - ACM certificate ARN (your account ID and certificate ID)
   - Route 53 zone ID (from your hosted zone)
   - Your domain name

2. **Generate secrets** for all applications:
   ```bash
   # From repository root
   ./generate-secrets.sh > my-secrets.txt

   # IMPORTANT: Save my-secrets.txt securely (password manager)
   # DO NOT commit my-secrets.txt to version control
   ```

3. **Update secret files** with generated values:
   - `apps/langfuse/secret.yaml`
   - `apps/librechat/libre_chat_secret.yaml`
   - `apps/datahub-pre/my_sql_secret.yaml`
   - `apps/monitoring/kube-prom-stack.yaml`

4. **Update application domains** in values files:
   - `apps/langfuse/values.yaml` - Replace `langfuse.your-domain.example.com`
   - `apps/librechat/values.yaml` - Replace `chat.your-domain.example.com`
   - `apps/langflow-ide/values.yaml` - Replace `langflow-ide.your-domain.example.com`
   - `apps/datahub/values.yaml` - Replace `datahub.your-domain.example.com`

5. **Customize bootstrap.yaml** for your Git repository (if using GitOps):
   - Option 1: Update all `repoURL` entries with your Git repository
   - Option 2: Skip bootstrap.yaml and deploy applications manually with Helm

## Quick Start

### Step 1: Configure Variables

```bash
# Navigate to terraform configuration
cd terraform/environments/dev

# Edit terraform.tfvars with your values
vim terraform.tfvars

# Update ALL values marked with YOUR_ACCOUNT_ID, YOUR_CERT_ID, etc.
# See Prerequisites section above for what each value should be
```

### Step 2: Generate Secrets

```bash
# From repository root
./generate-secrets.sh > my-secrets.txt

# Store securely - you'll need these values
# DO NOT commit my-secrets.txt to version control

# Update secret files with generated values
# See "Before Deployment" section for list of files
```

### Step 3: Deploy Infrastructure

```bash
# From repository root
export TERRAFORM_STATE_BUCKET_NAME="your-terraform-state-bucket-name"
export AWS_REGION="us-east-1"

# Review what will be created (optional but recommended)
cd terraform/environments/dev
terraform init
terraform plan

# Deploy (takes ~15-20 minutes)
cd ../../..  # Back to repository root
./deploy.sh
```

This will:
1. Create S3 bucket for Terraform state (with versioning and encryption)
2. Initialize Terraform backend
3. Create VPC with public/private subnets across 3 AZs
4. Create EKS cluster with Auto Mode enabled
5. Deploy AWS Load Balancer Controller
6. Configure kubectl to access the cluster (~15-20 minutes total)

### Step 4: Verify Cluster Access

```bash
# Check cluster nodes (may take a few minutes for nodes to appear)
kubectl get nodes

# Check system pods
kubectl get pods -A

# Verify ArgoCD is running
kubectl get pods -n argocd
```

### Step 5: Access ArgoCD

```bash
# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo  # Print newline

# Port-forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser to https://localhost:8080
# Username: admin
# Password: (from command above)

# ⚠️ IMPORTANT: Change the default admin password after first login
```

### Step 6: Deploy Applications with ArgoCD

```bash
# Option 1: Using GitOps (requires updating bootstrap.yaml with your Git repo)
kubectl apply -f apps/bootstrap.yaml

# Option 2: Deploy individual applications manually
kubectl apply -f apps/langfuse/secret.yaml
kubectl apply -f apps/librechat/libre_chat_secret.yaml
kubectl apply -f apps/datahub-pre/my_sql_secret.yaml

# Then deploy via Helm (example for vLLM)
helm install vllm vllm-stack \
  --repo https://vllm-project.github.io/production-stack \
  --version 0.1.6 \
  --values apps/vllm/values.yaml \
  --namespace vllm --create-namespace
```

## Application Details

### vLLM - LLM Inference Server

**Purpose**: High-performance inference serving for large language models with OpenAI-compatible API

**Key Features**:
- OpenAI-compatible REST API (drop-in replacement for OpenAI SDK)
- Continuous batching for high throughput
- PagedAttention for efficient memory utilization
- GPU acceleration with NVIDIA T4 (g4dn instances)
- Automatic request queueing and load balancing

**Default Configuration**:
- Model: `facebook/opt-125m` (demo model - replace with your production model)
- Replicas: 1
- Resources: 6 CPU, 16Gi RAM, 1 GPU
- Namespace: `vllm`

**Access Locally**:
```bash
kubectl port-forward svc/vllm-router-service 30080:80 -n vllm

# Test with OpenAI-compatible API
curl http://localhost:30080/v1/models

curl -X POST http://localhost:30080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "prompt": "Once upon a time,",
    "max_tokens": 50
  }'
```

**Production Considerations**:
- Replace `facebook/opt-125m` with your production model
- Adjust replica count based on load
- Consider using larger instance types (g5.xlarge, p3.2xlarge) for larger models
- Enable autoscaling based on queue depth metrics

**Documentation**: [vLLM Production Stack](https://docs.vllm.ai/projects/production-stack/en/latest/)

---

### Langfuse - LLM Observability

**Purpose**: Track, monitor, and improve LLM applications with detailed observability

**Key Features**:
- End-to-end trace LLM requests (prompt → model → response)
- Token usage analytics and cost tracking
- Prompt versioning and A/B testing
- User feedback collection
- Team collaboration features

**Storage Dependencies**:
- PostgreSQL (deployed via Helm chart)
- ClickHouse (deployed via Helm chart)
- Redis (deployed via Helm chart)

**Access**: `https://langfuse.your-domain.com` (configure in `values.yaml`)

**Integration Example** (Python):
```python
from langfuse import Langfuse

langfuse = Langfuse(
    public_key="your-public-key",
    secret_key="your-secret-key",
    host="https://langfuse.your-domain.com"
)

# Trace an LLM call
trace = langfuse.trace(name="chat-completion")
generation = trace.generation(
    name="gpt-4-response",
    model="gpt-4",
    input={"messages": [{"role": "user", "content": "Hello"}]},
    output={"content": "Hi there!"}
)
```

**Documentation**: [Langfuse Docs](https://langfuse.com/docs)

---

### LibreChat - Multi-Model Chat Interface

**Purpose**: User-friendly chat interface supporting multiple LLM providers

**Key Features**:
- Multi-model support: OpenAI, Azure OpenAI, Anthropic, custom endpoints
- Conversation history with search
- File uploads (documents, images)
- Plugin system for extending functionality
- User authentication and role-based access

**Required Configuration**:
- Update `libre_chat_secret.yaml` with API keys for LLM providers
- For Azure OpenAI: Update `AZURE_API_KEY` in secret

**Access**: `https://chat.your-domain.com`

**User Management**:
- First user to register becomes admin
- Additional users can be invited by admin
- Supports LDAP/SAML integration (configuration required)

**Documentation**: [LibreChat Docs](https://www.librechat.ai/docs)

---

### Langflow IDE - Visual LLM Workflow Builder

**Purpose**: Low-code platform for building and testing LLM applications visually

**Key Features**:
- Drag-and-drop workflow designer
- Pre-built components for RAG, agents, chains, tools
- Testing and debugging interface
- Export workflows to Python code
- Component marketplace

**Common Use Cases**:
- Building RAG (Retrieval Augmented Generation) pipelines
- Creating LLM agents with tool calling
- Prototyping prompt chains
- Testing different LLM models and configurations

**Access**: `https://langflow-ide.your-domain.com`

**Getting Started**:
1. Open Langflow IDE in browser
2. Create a new flow or use a template
3. Drag components from sidebar (LLMs, Embeddings, Vector Stores, etc.)
4. Connect components to build your workflow
5. Test with the built-in playground
6. Export to Python when ready for production

**Documentation**: [Langflow Docs](https://docs.langflow.org/)

---

### DataHub - Data Discovery Platform

**Purpose**: Centralized metadata catalog and data governance platform

**Key Features**:
- Dataset and table discovery with search
- Data lineage tracking (upstream/downstream dependencies)
- Schema evolution tracking
- Data quality monitoring
- Glossary and tagging system

**Storage Dependencies**:
- MySQL (deployed via prerequisites chart)
- Elasticsearch (for search)
- Neo4j (for lineage graph)

**Access**: `https://datahub.your-domain.com`

**Integration**:
- Supports ingestion from: Snowflake, Redshift, S3, Glue, BigQuery, PostgreSQL, etc.
- Configure ingestion recipes in DataHub UI
- Use DataHub CLI or API for automated ingestion

**Documentation**: [DataHub Docs](https://datahubproject.io/docs)

---

### Monitoring Stack

**Components**:
- **Prometheus**: Metrics collection from all Kubernetes resources and applications
- **Grafana**: Pre-configured dashboards for Kubernetes cluster health and vLLM metrics
- **Prometheus Adapter**: Exposes custom metrics for Horizontal Pod Autoscaler (HPA)

**Default Credentials**:
- Grafana username: `admin`
- Grafana password: **CHANGE THIS** in `apps/monitoring/kube-prom-stack.yaml`

**Access Locally**:
```bash
# Grafana
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-grafana 3000:80
# Open http://localhost:3000

# Prometheus
kubectl port-forward -n monitoring \
  svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090
```

**Pre-Configured Dashboards**:
- Kubernetes cluster overview
- Node resource utilization
- Pod resource usage
- vLLM inference metrics (requests/sec, latency, GPU utilization)

**Adding Custom Dashboards**:
1. Log into Grafana
2. Create dashboard or import from [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
3. Recommended: Import dashboard for NVIDIA DCGM Exporter (ID: 12239)

---

## Security Considerations

### ⚠️ This is a Demo Configuration

This AI/ML platform deployment demonstrates high availability patterns and GitOps workflows, but is **NOT production-ready** without additional hardening. Address these critical security considerations before production use:

### Known Limitations

1. **EKS API Public Endpoint** - No IP restrictions (anyone can attempt authentication)
   - **Risk**: Exposed to internet-wide scanning and brute force attempts
   - **Fix**: Add `endpoint_public_access_cidrs` to restrict to your office/VPN IPs

2. **Secrets in Git** - Placeholder files tracked in version control
   - **Risk**: Easy to accidentally commit real secrets
   - **Fix**: Use External Secrets Operator to inject from AWS Secrets Manager

3. **Weak Default Passwords** - Must be changed before deployment
   - Grafana: `REPLACE_WITH_GENERATED_GRAFANA_PASSWORD`
   - MySQL: `REPLACE_WITH_GENERATED_MYSQL_PASSWORD`
   - Langfuse: Multiple passwords in `secret.yaml`

4. **Single Region** - No cross-region disaster recovery
   - **Risk**: Regional AWS outage causes complete downtime
   - **Fix**: Implement multi-region active-passive or active-active

5. **No Pod Security Standards** - Pods can run as root with any capabilities
   - **Risk**: Container breakout could compromise node
   - **Fix**: Implement Pod Security Standards (PSS) in enforcing mode

6. **No Network Policies** - All pods can communicate freely within cluster
   - **Risk**: Lateral movement after pod compromise
   - **Fix**: Implement NetworkPolicies to segment namespaces

7. **No Resource Quotas** - Unlimited resource usage per namespace
   - **Risk**: Runaway pod could exhaust cluster resources
   - **Fix**: Add ResourceQuotas and LimitRanges per namespace

8. **No Backup Configuration** - Databases have no automated backups
   - **Risk**: Data loss is permanent and unrecoverable
   - **Fix**: Configure Velero for cluster backups, enable database snapshots

### Recommended Production Enhancements

1. **Restrict EKS API Access**
   ```hcl
   # In terraform configuration
   cluster_endpoint_public_access_cidrs = ["YOUR_OFFICE_IP/32"]
   ```

2. **Implement External Secrets Operator**
   ```yaml
   # Store secrets in AWS Secrets Manager
   # Use ExternalSecret CRDs to inject into pods
   apiVersion: external-secrets.io/v1beta1
   kind: ExternalSecret
   metadata:
     name: langfuse-secrets
   spec:
     secretStoreRef:
       name: aws-secrets-manager
     target:
       name: langfuse
     data:
     - secretKey: salt
       remoteRef:
         key: aiml-platform/langfuse/salt
   ```

3. **Enable EKS Audit Logging**
   ```hcl
   enabled_cluster_log_types = ["audit", "api", "authenticator"]
   ```

4. **Configure Pod Security Standards**
   ```yaml
   # Apply to all namespaces except kube-system
   apiVersion: v1
   kind: Namespace
   metadata:
     name: vllm
     labels:
       pod-security.kubernetes.io/enforce: restricted
       pod-security.kubernetes.io/warn: restricted
   ```

5. **Implement Network Policies**
   ```yaml
   # Example: Isolate vLLM namespace
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: vllm-isolation
     namespace: vllm
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: monitoring
   ```

6. **Add Resource Quotas**
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: vllm-quota
     namespace: vllm
   spec:
     hard:
       requests.cpu: "20"
       requests.memory: 100Gi
       requests.nvidia.com/gpu: "2"
   ```

7. **Configure Database Backups**
   - Install Velero for cluster-wide backups
   - Enable automated snapshots for RDS (if migrating from pod-based DBs)
   - Test restore procedures regularly

8. **Enable Container Image Scanning**
   - Enable ECR image scanning on push
   - Configure admission controller to block images with critical CVEs

9. **Implement RBAC for ArgoCD**
   - Create separate ArgoCD projects per team
   - Restrict access to production namespaces
   - Enable SSO with corporate identity provider

10. **Set up CloudWatch Container Insights**
    ```bash
    # Deploy Container Insights
    aws eks create-addon --cluster-name aiml-platform-cluster \
      --addon-name amazon-cloudwatch-observability
    ```

---

## Cost Considerations

Estimated monthly costs for running this platform (us-east-1 pricing, as of January 2026):

| Component | Configuration | Est. Cost per Hour | Est. Cost per Month | Notes |
|-----------|--------------|-------------------|---------------------|-------|
| **EKS Control Plane** | 1 cluster | $0.10/hr | $73/month | Fixed cost |
| **GPU Nodes** | 1× g4dn.2xlarge | $0.752/hr | $550/month | Per node, 1× T4 GPU, 8 vCPU, 32 GB RAM |
| **General Nodes** | 2× t3.medium | $0.084/hr | $61/month | Auto-scaled based on load |
| **NAT Gateway** | 2× (multi-AZ) | $0.09/hr | $66/month | Plus data transfer ($0.045/GB) |
| **Application Load Balancer** | 1× ALB | $0.0225/hr | $16/month | Plus LCU charges (~$0.008/LCU-hr) |
| **EBS Volumes** | ~100 GB GP3 | ~$8/month | $8/month | For pod persistent volumes |
| **Data Transfer** | Varies | Varies | ~$50/month | Estimate: 500 GB out to internet |
| **CloudWatch Logs** | ~10 GB ingestion | ~$5/month | $5/month | With 30-day retention |
| **Route 53** | 1 hosted zone | ~$0.50/month | $0.50/month | Plus query charges |
| | | | | |
| **Minimum Total** | | | **~$830/month** | With 1 GPU node running 24/7 |
| **Without GPU** | | | **~$280/month** | General workloads only |

### Cost Optimization Strategies

1. **Stop GPU Nodes When Not in Use**
   ```bash
   # Scale down vLLM deployment
   kubectl scale deployment vllm-deployment -n vllm --replicas=0

   # GPU nodes will automatically terminate after ~10 minutes
   ```
   **Savings**: $550/month if GPU nodes only run 8 hours/day

2. **Use Spot Instances for Non-Critical Workloads**
   - Configure Karpenter to use Spot instances for general node pool
   - **Savings**: ~60-70% on compute costs
   - **Trade-off**: Pods may be evicted with 2-minute warning

3. **Single NAT Gateway for Dev**
   - Use single NAT gateway instead of one per AZ
   - **Savings**: $33/month + data transfer costs
   - **Trade-off**: No NAT gateway redundancy

4. **Delete Cluster When Not in Use**
   ```bash
   ./destroy.sh
   ```
   **Savings**: $830/month
   **Important**: Back up any data first!

5. **Use Reserved Instances or Savings Plans**
   - For always-on control plane and base nodes
   - **Savings**: ~30-50% on EC2 costs
   - **Commitment**: 1 or 3 years

6. **Monitor Costs with AWS Cost Explorer**
   ```bash
   aws ce get-cost-and-usage \
     --time-period Start=2026-01-01,End=2026-01-31 \
     --granularity DAILY \
     --metrics "UnblendedCost" \
     --group-by Type=SERVICE
   ```

**⚠️ Important**: GPU nodes (g4dn instances) are the largest cost driver. Only run them when actively using ML inference workloads.

---

## Cleanup

**⚠️ CRITICAL WARNING**: This will PERMANENTLY DELETE ALL resources and data!

### Before Destroying

1. **Back up any important data**:
   - Langfuse PostgreSQL database
   - DataHub MySQL database
   - Any persistent volumes with user data
   - Export Grafana dashboards you want to keep

2. **Verify you're destroying the correct cluster**:
   ```bash
   aws eks list-clusters --region us-east-1
   kubectl config current-context
   ```

### Destroy Infrastructure

```bash
# From repository root
export TERRAFORM_STATE_BUCKET_NAME="your-terraform-state-bucket-name"
export AWS_REGION="us-east-1"

./destroy.sh

# Follow prompts carefully - you'll be asked to confirm multiple times
```

This will:
1. Ask for confirmation (type 'yes')
2. Show Terraform destroy plan
3. Ask for final confirmation (type 'yes' again)
4. Destroy all infrastructure (~10-15 minutes)
5. Optionally delete S3 bucket with Terraform state

### Post-Cleanup Verification

```bash
# Verify EKS cluster is deleted
aws eks list-clusters --region us-east-1

# Verify VPC is deleted
aws ec2 describe-vpcs --region us-east-1 \
  --filters "Name=tag:Name,Values=aiml-platform-vpc"

# Check for any remaining resources
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Terraform,Values=true
```

### Manual Cleanup (if needed)

If `terraform destroy` fails, you may need to manually delete:

```bash
# Delete any remaining load balancers
aws elbv2 describe-load-balancers --region us-east-1
aws elbv2 delete-load-balancer --load-balancer-arn <ARN>

# Delete any remaining security groups
aws ec2 describe-security-groups --region us-east-1 \
  --filters "Name=tag:Name,Values=*aiml-platform*"

# Delete CloudWatch log groups
aws logs describe-log-groups --region us-east-1 \
  --log-group-name-prefix "/aws/eks/aiml-platform"
aws logs delete-log-group --log-group-name <name>
```

---

## Troubleshooting

### EKS Cluster Creation Fails

**Symptom**: Terraform apply fails with "error creating EKS cluster"

**Common Causes**:
1. IAM role ARN is incorrect or doesn't exist
2. EKS Auto Mode not available in your region
3. Service quotas exceeded

**Resolution**:
```bash
# Verify IAM role exists
aws iam get-role --role-name YOUR_ROLE_NAME

# Check EKS service quotas
aws service-quotas list-service-quotas \
  --service-code eks --region us-east-1

# Verify EKS Auto Mode is available
aws eks describe-addon-versions --region us-east-1
```

---

### ArgoCD Applications Not Syncing

**Symptom**: Applications stuck in "Progressing" or "OutOfSync" state

**Common Causes**:
1. Git repository URL is incorrect or inaccessible
2. Missing SSH key or credentials for private repository
3. Values file path is wrong in Application spec

**Resolution**:
```bash
# Check ArgoCD logs
kubectl logs -n argocd deploy/argocd-repo-server

# Verify Git repository access
kubectl exec -n argocd deploy/argocd-repo-server -- \
  git ls-remote YOUR_REPO_URL

# Force sync from ArgoCD UI or CLI
argocd app sync APP_NAME --force
```

---

### vLLM Pod Not Starting

**Symptom**: vLLM pod stuck in "Pending" or "CrashLoopBackOff"

**Common Causes**:
1. No GPU nodes available in cluster
2. Model download failed (network timeout, invalid model name)
3. Insufficient GPU memory for model

**Resolution**:
```bash
# Check if GPU nodes exist
kubectl get nodes -l node.kubernetes.io/instance-type=g4dn.2xlarge

# Check pod events
kubectl describe pod -n vllm <pod-name>

# Check pod logs
kubectl logs -n vllm <pod-name>

# Common fix: Increase node count or use smaller model
# Edit apps/vllm/values.yaml:
#   model: "facebook/opt-125m"  # Smaller model for testing
```

---

### Langfuse Database Migration Failed

**Symptom**: Langfuse web pod logs show "Dirty database version" error

**Resolution**:
```bash
# Connect to ClickHouse pod
kubectl exec -it -n langfuse <langfuse-clickhouse-pod> -- clickhouse-client

# Drop schema_migrations table
DROP TABLE default.schema_migrations ON CLUSTER default;
DROP TABLE default.traces ON CLUSTER default;

# Restart Langfuse web pod
kubectl delete pod -n langfuse -l app=langfuse-web
```

---

### SSL Certificate Errors

**Symptom**: Browser shows "Invalid Certificate" when accessing applications

**Common Causes**:
1. ACM certificate doesn't cover the domain
2. DNS records not propagating yet
3. ALB not associated with correct certificate

**Resolution**:
```bash
# Verify ACM certificate status
aws acm describe-certificate \
  --certificate-arn YOUR_CERT_ARN \
  --region us-east-1

# Check ALB listeners
kubectl get ingress -A
kubectl describe ingress -n langfuse

# Verify DNS resolution
dig langfuse.your-domain.com
nslookup langfuse.your-domain.com
```

---

### High AWS Costs

**Symptom**: Unexpected high charges on AWS bill

**Common Causes**:
1. GPU nodes running 24/7
2. NAT Gateway data transfer charges
3. ALB LCU charges from high traffic
4. EBS volumes not deleted after cluster destruction

**Resolution**:
```bash
# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-16 \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --group-by Type=SERVICE

# Scale down GPU workloads
kubectl scale deployment vllm-deployment -n vllm --replicas=0

# Check for orphaned EBS volumes
aws ec2 describe-volumes --region us-east-1 \
  --filters "Name=status,Values=available"

# Delete unused volumes
aws ec2 delete-volume --volume-id <volume-id>
```

---

## Further Reading

### AWS Documentation
- [Amazon EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [EKS Auto Mode Documentation](https://docs.aws.amazon.com/eks/latest/userguide/auto-mode.html)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Kubernetes & GitOps
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Helm Documentation](https://helm.sh/docs/)

### AI/ML Tools
- [vLLM Documentation](https://docs.vllm.ai/)
- [Langfuse Documentation](https://langfuse.com/docs)
- [LibreChat Documentation](https://www.librechat.ai/docs)
- [Langflow Documentation](https://docs.langflow.org/)
- [DataHub Documentation](https://datahubproject.io/docs)

### Observability
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Operator](https://prometheus-operator.dev/)
