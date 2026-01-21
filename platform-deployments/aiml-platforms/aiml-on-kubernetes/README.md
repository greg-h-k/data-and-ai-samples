# AI/ML Platform on Amazon EKS

The purpose of this sample is to show how you can quickly deploy AI/ML related applications on Amazon EKS with automated GitOps deployment via ArgoCD. 

**This is a demonstration deployment for development and testing purposes.The deployed apps do not have user authentication and authorization configured, this is for ease of demo only. You must protect access to the applications.**

## Overview

### What This Platform Provides

This repo shows how you can deploy a variety of related AI applications on Kubernetes, focusing on common AI requirements such as building AI powered workflows, serving internal chat based apps, serving LLMs for inference and moniroting these models.

**Core Components:**
- **Amazon EKS** with EKS Auto Mode - Managed Kubernetes cluster with automatic compute provisioning
- **GPU Node Pool** - g4dn instances with NVIDIA T4 GPUs for model inference workloads
- **ArgoCD** - GitOps continuous deployment for declarative application management

**AI/ML Applications** (optional, can be enabled/disabled individually):
- **vLLM** - High-performance LLM inference serving with OpenAI-compatible API
- **Langfuse** - LLM observability and analytics for tracking prompts, costs, and performance
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

The sample inlcudes showing how you can register the applications with host names on Route 53, this is optional and you can override this if you prefer. 

1. **AWS Account** with permissions to create:
   - VPC, subnets, NAT gateways, Internet gateways, Application Load Balancers
   - EKS clusters (with EKS Auto Mode enabled in your region)
   - IAM roles, policies, and OIDC providers
   - Route 53 hosted zones and DNS records
   - ACM certificates for SSL/TLS
   - ECR repositories for container images

2. **ACM Certificate** in target region:
   - Must cover your domain (for example: `*.your-domain.com`)
   - Must be validated (DNS or email validation) before deployment
   - Certificate ARN will be needed for `terraform.tfvars`

3. **Route 53 Hosted Zone**:
   - Public hosted zone for your domain
   - Note the Zone ID (visible in Route 53 console) - needed for `terraform.tfvars`
   - Ensure NS records are properly delegated if using subdomain

4. **IAM Admin Role**:
   - Role that serves as amdministrator with relevant permissions to access and manage resources
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

1. **Create terraform.tfvars** from the example with your AWS account values:
   Update:
   - AWS region
   - IAM admin role ARN (your account ID and role name)

   If you want to use Route53:
   - ACM certificate ARN (your account ID and certificate ID)
   - Route 53 zone ID (from your hosted zone)
   - Your domain name

2. **Generate secrets** for all applications:
   ```bash
   # From sample root
   ./generate-and-upload-secrets.sh
   ```

3. **Update application domains** in values files, this ensures the ingress works with your domain. Note this sample is configured with internet-facing egress. You can limit access to your IP address via the load balancer security group, but you may want to update the ingress specifications and the alb ingress class to suit your requirements. 
   - `apps/langfuse/values.yaml` - Replace `langfuse.your-domain.example.com`
   - `apps/langflow-ide/values.yaml` - Replace `langflow-ide.your-domain.example.com`
   - `apps/datahub/values.yaml` - Replace `datahub.your-domain.example.com`

5. **Customize bootstrap.yaml** for your Git repository (if using GitOps):
   - If using ArgoCD, commit the updated values files to your repo so they can be accessed GitOps deployment
   - Using ArgoCD GitOps approach, Argo will sync changes from your Git repo and apply them to your kubernetes cluster. 
   - Ensure to add your repository to ArgoCD and to update the repo link in the bootstrap file. 

## Quick Start

### Step 1: Configure Variables

```bash
# Navigate to terraform configuration
cd terraform/environments/dev

# Edit terraform.tfvars with your values
cp terraform.example.tfvars terraform.tfvars
vim terraform.tfvars

# Update ALL values marked with YOUR_ACCOUNT_ID, YOUR_CERT_ID, etc.
# See Prerequisites section above for what each value should be
```

### Step 2: Generate and Upload Secrets to AWS Secrets Manager

The platform uses **AWS Secrets Manager** with **External Secrets Operator** for automatic secret injection. Secrets are generated and stored securely in AWS, then automatically synced to Kubernetes.

Back in the sample root:

```bash
# Generate random secrets and upload to AWS Secrets Manager
./generate-and-upload-secrets.sh --region us-east-1

# The script will create 16 secrets in AWS Secrets Manager:
# - aiml-platform/langfuse/* (8 secrets)
# - aiml-platform/datahub/* (2 secrets)
# - aiml-platform/monitoring/* (1 secret)
```


### Step 3: Deploy Infrastructure

```bash
# From repository root
export TERRAFORM_STATE_BUCKET_NAME="your-terraform-state-bucket-name"
export AWS_REGION="us-east-1"

# Review what will be created (optional but recommended)
cd terraform/environments/dev
terraform init -upgrade
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
6. Deploy External Secrets Operator with IAM role for AWS Secrets Manager access
7. Create ClusterSecretStore for secret synchronization
8. Configure kubectl to access the cluster (~15-20 minutes total)

### Step 4: Verify Cluster Access

```bash
# Check cluster nodes (may take a few minutes for nodes to appear)
kubectl get nodes

# Check system pods
kubectl get pods -A

# Verify ArgoCD is running
kubectl get pods -n argocd

# Verify External Secrets Operator is running
kubectl get pods -n external-secrets

# Verify ClusterSecretStore is ready
kubectl get clustersecretstore aws-secrets-manager
# Expected: STATUS should show "Valid" and READY should be "True"
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

### Step 5.5: Verify Secret Management Infrastructure

Before deploying applications, verify that the secret management components are ready:

```bash
# Check External Secrets Operator is running
kubectl get pods -n external-secrets

# Verify ClusterSecretStore exists and is ready
kubectl get clustersecretstore aws-secrets-manager

# Check detailed status (should show Conditions: Ready=True)
kubectl describe clustersecretstore aws-secrets-manager

# Expected output should include:
# Status:
#   Conditions:
#     Status:  True
#     Type:    Ready
```

**If the ClusterSecretStore is missing or not ready:**

```bash
# Apply the ClusterSecretStore manually
kubectl apply -f apps/external-secrets-operator/cluster-secret-store.yaml

# Wait for it to become ready
kubectl wait --for=condition=Ready clustersecretstore/aws-secrets-manager --timeout=60s

# If it still doesn't become ready, check ESO logs
kubectl logs -n external-secrets deployment/external-secrets --tail=50
```

**Common issues:**
- IRSA not configured: Check service account has IAM role annotation
  ```bash
  kubectl get sa external-secrets-sa -n external-secrets -o yaml | grep eks.amazonaws.com/role-arn
  ```
- Region mismatch: Ensure the region in the ClusterSecretStore matches where your secrets are stored
- IAM permissions: Verify the IAM role has `secretsmanager:GetSecretValue` permission

### Step 6: Deploy ExternalSecrets

Before deploying applications, apply the ExternalSecret manifests to sync secrets from AWS Secrets Manager:

```bash
# Create namespaces
kubectl create namespace langfuse --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace datahub --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Apply ExternalSecret resources
kubectl apply -f apps/langfuse/external-secret.yaml
kubectl apply -f apps/datahub-pre/mysql-external-secret.yaml
kubectl apply -f apps/datahub-pre/neo4j-external-secret.yaml
kubectl apply -f apps/monitoring/grafana-external-secret.yaml

# Verify secrets are synced (Status should be "SecretSynced")
kubectl get externalsecrets -A

# Verify Kubernetes secrets were created
kubectl get secrets -n langfuse langfuse
kubectl get secrets -n datahub mysql-secrets
kubectl get secrets -n datahub neo4j-secrets
kubectl get secrets -n monitoring grafana-admin-credentials
```

### Step 7: Deploy Applications with ArgoCD

With secrets synced, deploy the applications:

**Option 1: Using GitOps with ArgoCD (Recommended)**

Requires updating bootstrap.yaml with your Git repository URL, adding your repository to ArgoCD and pushing the project with your updated value.yaml files to your repo:

```bash
kubectl apply -f apps/bootstrap.yaml
```

**Option 2: Deploy Individual Applications Manually via Helm**

Deploy applications one-by-one using Helm. Secrets are already created by ExternalSecrets in the previous step.

**IMPORTANT - First-time setup:**
```bash
# Copy example values files and customize with your configuration
cd apps/<application>/
cp values.example.yaml values.yaml
vim values.yaml  # Update domain names, certificate ARNs, etc.
```

See [apps/README.md](apps/README.md) for detailed configuration instructions.

**vLLM (LLM Inference Server):**
```bash
helm install vllm vllm-stack \
  --repo https://vllm-project.github.io/production-stack \
  --version 0.1.6 \
  --values apps/vllm/values.yaml \
  --namespace vllm --create-namespace
```

**Langfuse (LLM Observability):**
```bash
helm install langfuse langfuse \
  --repo https://langfuse.github.io/langfuse-k8s \
  --version 1.2.18 \
  --values apps/langfuse/values.yaml \
  --namespace langfuse --create-namespace
```

**Langflow IDE (Visual AI Workflow Builder):**
```bash
helm install langflow-ide langflow-ide \
  --repo https://langflow-ai.github.io/langflow-helm-charts \
  --version 0.1.1 \
  --values apps/langflow-ide/values.yaml \
  --namespace langflow-ide --create-namespace
```

**DataHub (Data Catalog and Governance):**

DataHub requires two-step deployment. Deploy prerequisites first:

```bash
# Step 1: Deploy DataHub prerequisites (MySQL, Neo4j, Elasticsearch, Kafka)
helm install datahub-prerequisites datahub-prerequisites \
  --repo https://helm.datahubproject.io/ \
  --version 0.1.15 \
  --values apps/datahub-pre/values.yaml \
  --namespace datahub --create-namespace

# Wait for prerequisites to be ready (can take 5-10 minutes)
kubectl get pods -n datahub -w

# Step 2: Deploy DataHub main application
helm install datahub datahub \
  --repo https://helm.datahubproject.io/ \
  --version 0.6.13 \
  --values apps/datahub/values.yaml \
  --namespace datahub
```

**Monitoring Stack (Prometheus + Grafana):**

```bash
# Deploy Prometheus and Grafana
helm install kube-prometheus-stack kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  --version 77.0.0 \
  --values apps/monitoring/kube-prom-stack.yaml \
  --namespace monitoring --create-namespace

# Deploy Prometheus Adapter (for custom metrics)
helm install prometheus-adapter prometheus-adapter \
  --repo https://prometheus-community.github.io/helm-charts \
  --version 5.1.0 \
  --values apps/monitoring/prometheus-adapter.yaml \
  --namespace monitoring
```

## Secret Management Architecture

This platform uses **External Secrets Operator (ESO)** to automatically sync secrets from AWS Secrets Manager to Kubernetes, eliminating manual secret handling and enabling GitOps-friendly workflows.

### How It Works

```
┌────────────────────────────┐
│  AWS Secrets Manager       │
│  aiml-platform/langfuse/*  │ ─┐
│  aiml-platform/datahub/*   │  │  IRSA (IAM Role for Service Account)
│  aiml-platform/monitoring/*│  │  ESO pod authenticates with AWS
└────────────────────────────┘  │
                                │
                                ▼
┌────────────────────────────────────────────────────┐
│  ClusterSecretStore (aws-secrets-manager)          │
│  - Cluster-wide configuration                      │
│  - Provides AWS authentication context             │
│  - References IRSA service account                 │
└─────────────────────────┬──────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│  External Secrets Operator (ESO)                   │
│  - Runs in external-secrets namespace              │
│  - Polls AWS Secrets Manager every hour            │
│  - Creates/updates Kubernetes Secrets              │
└─────────────────────────┬──────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│  ExternalSecret Resources (per-application)        │
│  langfuse/external-secret                          │
│  datahub-pre/mysql-external-secret                 │
│  datahub-pre/neo4j-external-secret                 │
│  monitoring/grafana-external-secret                │
└─────────────────────────┬──────────────────────────┘
                          │
                          ▼
┌────────────────────────────────────────────────────┐
│  Kubernetes Secrets (auto-created)                 │
│  langfuse/langfuse                                 │
│  datahub/mysql-secrets, datahub/neo4j-secrets     │
│  monitoring/grafana-admin-credentials              │
└─────────────────────────┬──────────────────────────┘
                          │
                          ▼
                    Application Pods
```

### Benefits

- **No manual secret file editing** - Secrets never touch Git or local files
- **Centralized management** - All secrets in AWS Secrets Manager
- **Automatic synchronization** - Changes in AWS propagate to Kubernetes within 1 hour
- **Rotation support** - Update secrets in AWS, ESO syncs automatically
- **Audit trail** - CloudTrail logs all secret access
- **GitOps-friendly** - ExternalSecret manifests (references, not values) checked into Git

### Rotating a Secret

```bash
# 1. Update in AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id aiml-platform/langfuse/postgresql-password \
  --secret-string 'NEW_SECURE_PASSWORD' \
  --region us-east-1

# 2. ESO syncs within 1 hour (or force immediate sync)
kubectl annotate externalsecret langfuse -n langfuse \
  force-sync=$(date +%s) --overwrite

# 3. Restart application to use new secret
kubectl rollout restart deployment -n langfuse
```

### Cost

- **AWS Secrets Manager**: $0.40/month per secret × 16 secrets = **~$6.40/month**
- **API calls**: $0.05 per 10,000 calls (likely within free tier with 1h refresh)
- **External Secrets Operator**: Free (open source, runs on existing EKS nodes)

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
Retrieve from cluster or AWS secrets manager. 

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

3. **Delete secrets from AWS Secrets Manager** (to avoid ongoing costs of ~$6.40/month):
   ```bash
   # List all platform secrets
   aws secretsmanager list-secrets \
     --filters Key=name,Values=aiml-platform/ \
     --region us-east-1 \
     --query 'SecretList[].Name' \
     --output text

   # Delete all secrets at once (force delete without recovery window)
   for secret in $(aws secretsmanager list-secrets \
     --filters Key=name,Values=aiml-platform/ \
     --region us-east-1 \
     --query 'SecretList[].Name' \
     --output text); do
     echo "Deleting $secret"
     aws secretsmanager delete-secret \
       --secret-id "$secret" \
       --force-delete-without-recovery \
       --region us-east-1
   done
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
- [Langflow Documentation](https://docs.langflow.org/)
- [DataHub Documentation](https://datahubproject.io/docs)

### Observability
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Operator](https://prometheus-operator.dev/)
