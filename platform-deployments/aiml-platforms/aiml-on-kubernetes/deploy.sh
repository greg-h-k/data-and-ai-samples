#!/bin/bash
# ============================================================================
# AI/ML Platform Deployment Script
# ============================================================================
# This script automates the deployment of the AI/ML platform infrastructure:
# 1. Creates S3 bucket for Terraform state (if it doesn't exist)
# 2. Initializes Terraform with remote backend
# 3. Applies Terraform configuration to create EKS cluster and resources
# 4. Configures kubectl to connect to the new cluster
#
# PREREQUISITES:
# - AWS CLI v2.x configured with appropriate credentials
# - Terraform v1.5+
# - kubectl v1.28+
# - Environment variables set:
#     TERRAFORM_STATE_BUCKET_NAME: S3 bucket for Terraform state
#     AWS_REGION: AWS region for deployment (e.g., us-east-1)
#
# IMPORTANT BEFORE RUNNING:
# 1. Update terraform/environments/dev/terraform.tfvars with your values
# 2. Generate secrets 
#
# USAGE:
#     export TERRAFORM_STATE_BUCKET_NAME="my-terraform-state-bucket"
#     export AWS_REGION="us-east-1"
#     ./deploy.sh
#
# WARNING: This script uses -auto-approve for Terraform apply, which is
# convenient for demos but NOT recommended for production. Review the
# Terraform plan manually before applying in production environments.
# ============================================================================

set -e  # Exit on error

# Validate required environment variables
if [ -z "$TERRAFORM_STATE_BUCKET_NAME" ]; then
    echo "❌ ERROR: TERRAFORM_STATE_BUCKET_NAME environment variable is not set"
    echo "Usage: export TERRAFORM_STATE_BUCKET_NAME=your-bucket-name"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo "❌ ERROR: AWS_REGION environment variable is not set"
    echo "Usage: export AWS_REGION=us-east-1"
    exit 1
fi

# Configuration
TERRAFORM_STATE_BUCKET_NAME=$TERRAFORM_STATE_BUCKET_NAME
AWS_REGION=$AWS_REGION
STATE_KEY="aiml-platform/terraform.tfstate"

echo "============================================================================"
echo "AI/ML Platform Deployment"
echo "============================================================================"
echo "State bucket: $TERRAFORM_STATE_BUCKET_NAME"
echo "Region: $AWS_REGION"
echo "State key: $STATE_KEY"
echo "============================================================================"
echo ""
echo "🚀 Starting Terraform deployment with S3 backend..."

# Step 1: Create S3 bucket using AWS CLI
echo "📦 Creating S3 bucket for Terraform state..."
if ! aws s3api head-bucket --bucket "$TERRAFORM_STATE_BUCKET_NAME" 2>/dev/null; then
    # us-east-1 is special and does not accept LocationConstraint
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$TERRAFORM_STATE_BUCKET_NAME" \
            --region "$AWS_REGION"
    else
        aws s3api create-bucket \
            --bucket "$TERRAFORM_STATE_BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    
    aws s3api put-bucket-versioning \
        --bucket "$TERRAFORM_STATE_BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    aws s3api put-bucket-encryption \
        --bucket "$TERRAFORM_STATE_BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
else
    echo "Bucket already exists, skipping creation"
fi

echo "✅ S3 bucket ready"

# Step 2: Configure and deploy main Terraform
echo "🏗️  Deploying main infrastructure..."
cd ./terraform/environments/dev
terraform init -upgrade \
  -backend-config="bucket=${TERRAFORM_STATE_BUCKET_NAME}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="region=${AWS_REGION}"

# Two-stage deployment to handle kubernetes provider dependency
echo ""
echo "📦 Stage 1: Creating VPC and EKS cluster..."
terraform apply -auto-approve \
  -target=module.baseline_environment_network \
  -target=module.eks.module.eks

echo ""
echo "⏳ Waiting 30 seconds for EKS cluster to stabilize..."
sleep 30

echo ""
echo "🔧 Stage 2: Deploying Kubernetes resources and remaining infrastructure..."
terraform apply -auto-approve

# Step 3: Configure kubectl
echo "⚙️  Configuring kubectl..."
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}

echo ""
echo "🔐 Creating ClusterSecretStore for AWS Secrets Manager..."
cd ../../..
kubectl apply -f apps/external-secrets-operator/cluster-secret-store.yaml

echo "⏳ Waiting for ClusterSecretStore to be ready..."
kubectl wait --for=condition=Ready clustersecretstore/aws-secrets-manager --timeout=60s || {
    echo "⚠️  ClusterSecretStore not ready yet. Check status with:"
    echo "    kubectl describe clustersecretstore aws-secrets-manager"
}

echo ""
echo "🎉 Deployment completed successfully!"
echo "📍 Terraform state is stored in: s3://${TERRAFORM_STATE_BUCKET_NAME}/${STATE_KEY}"
echo "🔧 kubectl configured for cluster: ${EKS_CLUSTER_NAME}"
echo "✅ Test cluster access: kubectl get nodes"
echo "🔐 Verify ClusterSecretStore: kubectl get clustersecretstore aws-secrets-manager"