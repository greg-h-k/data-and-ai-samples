#!/bin/bash
# ============================================================================
# AI/ML Platform Secret Generation and AWS Secrets Manager Upload
# ============================================================================
# This script generates secure random secrets for all applications and
# uploads them directly to AWS Secrets Manager.
#
# PREREQUISITES:
# - AWS CLI configured with credentials
# - Permissions to create secrets in AWS Secrets Manager
# - Terraform infrastructure deployed (for proper IAM roles)
#
# USAGE:
#     ./generate-and-upload-secrets.sh [--region us-east-1] [--dry-run] [--force]
#
# OPTIONS:
#     --region REGION    AWS region to store secrets (default: us-east-1)
#     --dry-run          Print commands without executing
#     --force            Overwrite existing secrets
#     --help             Show this help message
# ============================================================================

set -e

# Default values
AWS_REGION="us-east-1"
DRY_RUN=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
      ;;
    --help)
      grep '^#' "$0" | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--region REGION] [--dry-run] [--force] [--help]"
      exit 1
      ;;
  esac
done

echo "============================================================================"
echo "AI/ML Platform - Secret Generation and Upload to AWS Secrets Manager"
echo "============================================================================"
echo "Region: $AWS_REGION"
echo "Dry Run: $DRY_RUN"
echo "Force Overwrite: $FORCE"
echo "============================================================================"
echo ""

# Function to create or update secret
create_secret() {
  local secret_name=$1
  local secret_value=$2
  local description=$3

  if [ "$DRY_RUN" = true ]; then
    echo "  [DRY RUN] Would create secret: $secret_name"
    echo "            Value: ${secret_value:0:10}... (truncated)"
    return
  fi

  # Check if secret exists
  if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$AWS_REGION" >/dev/null 2>&1; then
    if [ "$FORCE" = true ]; then
      echo "  ↻ Updating existing secret: $secret_name"
      aws secretsmanager update-secret \
        --secret-id "$secret_name" \
        --secret-string "$secret_value" \
        --region "$AWS_REGION" \
        --description "$description" \
        >/dev/null
    else
      echo "  ⊘ Secret already exists (use --force to overwrite): $secret_name"
    fi
  else
    echo "  ✓ Creating secret: $secret_name"
    aws secretsmanager create-secret \
      --name "$secret_name" \
      --secret-string "$secret_value" \
      --description "$description" \
      --region "$AWS_REGION" \
      --tags Key=Platform,Value=aiml-eks Key=ManagedBy,Value=script Key=Environment,Value=dev \
      >/dev/null
  fi
}

echo "Generating and uploading secrets..."
echo ""

# ============================================================================
# Langfuse Secrets (8 secrets)
# ============================================================================

echo "━━━ Langfuse Secrets ━━━"

create_secret "aiml-platform/langfuse/salt" \
  "$(openssl rand -base64 32)" \
  "Langfuse encryption salt"

create_secret "aiml-platform/langfuse/encryption-key" \
  "$(openssl rand -hex 32)" \
  "Langfuse encryption key (64-char hex)"

create_secret "aiml-platform/langfuse/nextauth-secret" \
  "$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-32)" \
  "NextAuth.js secret for Langfuse"

create_secret "aiml-platform/langfuse/postgresql-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "PostgreSQL password for Langfuse"

create_secret "aiml-platform/langfuse/clickhouse-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "ClickHouse password for Langfuse"

create_secret "aiml-platform/langfuse/redis-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "Redis password for Langfuse"

create_secret "aiml-platform/langfuse/s3-user" \
  "admin" \
  "S3 user for Langfuse"

create_secret "aiml-platform/langfuse/s3-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "S3 password for Langfuse"

echo ""

# ============================================================================
# DataHub Secrets (2 secrets)
# ============================================================================

echo "━━━ DataHub Secrets ━━━"

create_secret "aiml-platform/datahub/mysql-root-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "MySQL root password for DataHub"

create_secret "aiml-platform/datahub/neo4j-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "Neo4j password for DataHub"

echo ""

# ============================================================================
# Monitoring Secrets (1 secret)
# ============================================================================

echo "━━━ Monitoring Secrets ━━━"

create_secret "aiml-platform/monitoring/grafana-admin-password" \
  "$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)" \
  "Grafana admin password"

echo ""
echo "============================================================================"
echo "Secret generation complete!"
echo "============================================================================"
echo ""
