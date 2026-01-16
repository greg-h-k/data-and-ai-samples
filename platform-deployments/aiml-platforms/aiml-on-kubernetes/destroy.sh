#!/bin/bash
# ============================================================================
# AI/ML Platform Destruction Script
# ============================================================================
# ⚠️  CRITICAL WARNING: This script will PERMANENTLY DELETE ALL resources!
#
# This includes:
# - EKS cluster and all workloads
# - VPC, subnets, NAT gateways, ALB
# - All data in databases (Langfuse PostgreSQL, DataHub MySQL, etc.)
# - All persistent volumes and data
# - Route 53 DNS records
# - CloudWatch logs (if configured)
#
# DATA LOSS IS PERMANENT AND CANNOT BE RECOVERED!
#
# BEFORE RUNNING THIS SCRIPT:
# 1. ✅ Back up any important data from:
#    - Langfuse PostgreSQL database
#    - DataHub MySQL database
#    - Any persistent volumes with user data
# 2. ✅ Export any dashboards or configurations you want to keep
# 3. ✅ Save any logs or metrics you need
# 4. ✅ Verify you're destroying the correct cluster
#
# PREREQUISITES:
# - AWS CLI v2.x configured with appropriate credentials
# - Terraform v1.5+
# - kubectl v1.28+ (optional, for manual cleanup)
# - Environment variables set:
#     TERRAFORM_STATE_BUCKET_NAME: S3 bucket for Terraform state
#     AWS_REGION: AWS region where resources are deployed
#
# USAGE:
#     export TERRAFORM_STATE_BUCKET_NAME="my-terraform-state-bucket"
#     export AWS_REGION="us-east-1"
#     ./destroy.sh
#
# WARNING: This script uses -auto-approve for Terraform destroy, which will
# not prompt for confirmation. Review the Terraform plan carefully before
# running in production environments.
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

echo "============================================================================"
echo "⚠️  AI/ML Platform Infrastructure Destruction"
echo "============================================================================"
echo "State bucket: $TERRAFORM_STATE_BUCKET_NAME"
echo "Region: $AWS_REGION"
echo "============================================================================"
echo ""
echo "⚠️  WARNING: This will PERMANENTLY DELETE all infrastructure!"
echo "   - EKS cluster and all workloads"
echo "   - All databases and their data"
echo "   - VPC and networking resources"
echo "   - Route 53 DNS records"
echo ""
echo "   This action CANNOT be undone!"
echo ""
read -p "Are you absolutely sure you want to continue? (type 'yes' to confirm): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 0
fi

echo ""
echo "🗑️  Starting infrastructure cleanup..."
echo ""

# Step 1: Destroy main infrastructure
echo "🏗️  Destroying main infrastructure..."
cd terraform/environments/dev

# Initialize Terraform with backend config
terraform init -upgrade \
  -backend-config="bucket=${TERRAFORM_STATE_BUCKET_NAME}" \
  -backend-config="key=aiml-platform/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}"

# Show destroy plan (optional - comment out if you want to skip)
echo ""
echo "📋 Terraform destroy plan:"
terraform plan -destroy

echo ""
read -p "Proceed with destruction? (type 'yes' to confirm again): " final_confirmation

if [ "$final_confirmation" != "yes" ]; then
    echo "❌ Destruction cancelled"
    exit 0
fi

# Destroy resources
terraform destroy -auto-approve

echo ""
echo "✅ Main infrastructure destroyed"

# Step 2: Optionally destroy S3 bucket containing Terraform state
echo ""
echo "============================================================================"
echo "S3 Bucket Cleanup (Optional)"
echo "============================================================================"
echo "The S3 bucket containing Terraform state still exists:"
echo "  Bucket: s3://${TERRAFORM_STATE_BUCKET_NAME}"
echo ""
echo "⚠️  Deleting this bucket will remove all Terraform state history!"
echo ""
read -p "Do you want to delete the S3 bucket? (type 'yes' to confirm): " bucket_confirmation

if [ "$bucket_confirmation" == "yes" ]; then
    echo "📦 Destroying S3 bucket..."
    aws s3 rm s3://${TERRAFORM_STATE_BUCKET_NAME} --recursive
    aws s3api delete-bucket --bucket ${TERRAFORM_STATE_BUCKET_NAME} --region ${AWS_REGION}
    echo "✅ S3 bucket destroyed"
else
    echo "ℹ️  S3 bucket preserved: s3://${TERRAFORM_STATE_BUCKET_NAME}"
    echo "   You can manually delete it later if needed"
fi

echo ""
echo "============================================================================"
echo "🎉 Cleanup completed!"
echo "============================================================================"
echo ""
echo "Destroyed resources:"
echo "  ✓ EKS cluster and workloads"
echo "  ✓ VPC and networking"
echo "  ✓ Load balancers and target groups"
echo "  ✓ IAM roles and policies"
echo "  ✓ Route 53 records"
echo ""
echo "Remaining resources (if any):"
echo "  - S3 bucket (if you chose to keep it)"
echo "  - CloudWatch log groups (may require manual deletion)"
echo "  - ACM certificates (reusable for future deployments)"
echo ""
echo "💡 TIP: Check AWS Console to verify all resources are deleted"
echo "   Cost Explorer may show residual charges for a few hours"
echo "============================================================================"
