#!/bin/bash
# ============================================================================
# AI/ML Platform Secret Generation Script
# ============================================================================
# This script generates secure random secrets for all applications in the
# AI/ML platform deployment. Run this script BEFORE deploying to generate
# strong passwords and keys.
#
# USAGE:
#     ./generate-secrets.sh > my-secrets.txt
#
# IMPORTANT:
# - Save the output securely - you'll need these values for deployment
# - Update the respective secret files in apps/ directories with these values
# - NEVER commit the output file to version control
# - For production, consider using AWS Secrets Manager or External Secrets
# ============================================================================

set -e  # Exit on error

echo "============================================================================"
echo "AI/ML Platform - Secure Secret Generation"
echo "============================================================================"
echo ""
echo "⚠️  IMPORTANT: Save this output securely!"
echo "   These secrets will be needed to configure your deployment."
echo ""
echo "============================================================================"
echo ""

# Langfuse Secrets
echo "# ============================================================================"
echo "# Langfuse Secrets (apps/langfuse/secret.yaml)"
echo "# ============================================================================"
echo "LANGFUSE_SALT=\"$(openssl rand -base64 32)\""
echo "LANGFUSE_ENCRYPTION_KEY=\"$(openssl rand -hex 32)\""
echo "LANGFUSE_NEXTAUTH_SECRET=\"$(openssl rand -base64 32 | tr -d '=+/' | cut -c1-32)\""
echo "LANGFUSE_POSTGRES_PASSWORD=\"$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)\""
echo "LANGFUSE_CLICKHOUSE_PASSWORD=\"$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)\""
echo "LANGFUSE_REDIS_PASSWORD=\"$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)\""
echo "LANGFUSE_S3_USER=\"admin\""
echo "LANGFUSE_S3_PASSWORD=\"$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)\""
echo ""

# LibreChat Secrets
echo "# ============================================================================"
echo "# LibreChat Secrets (apps/librechat/libre_chat_secret.yaml)"
echo "# ============================================================================"
echo "LIBRECHAT_CREDS_KEY=\"$(openssl rand -hex 32)\""
echo "LIBRECHAT_JWT_SECRET=\"$(openssl rand -hex 32)\""
echo "LIBRECHAT_JWT_REFRESH_SECRET=\"$(openssl rand -hex 32)\""
echo "LIBRECHAT_MEILI_MASTER_KEY=\"$(openssl rand -hex 16)\""
echo "# ⚠️ AZURE_API_KEY: Get from Azure Portal → Azure OpenAI → Keys and Endpoint"
echo "# LIBRECHAT_AZURE_API_KEY=\"YOUR_AZURE_API_KEY_HERE\""
echo ""

# DataHub MySQL Secret
echo "# ============================================================================"
echo "# DataHub MySQL Secret (apps/datahub-pre/my_sql_secret.yaml)"
echo "# ============================================================================"
echo "MYSQL_ROOT_PASSWORD=\"$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)\""
echo ""

# Grafana Admin Password
echo "# ============================================================================"
echo "# Grafana Admin Password (apps/monitoring/kube-prom-stack.yaml)"
echo "# ============================================================================"
echo "GRAFANA_ADMIN_PASSWORD=\"$(openssl rand -base64 20 | tr -d '=+/' | cut -c1-20)\""
echo ""

echo "# ============================================================================"
echo "# Next Steps"
echo "# ============================================================================"
echo "# 1. Save this output to a secure location (e.g., password manager)"
echo "# 2. Update the following files with the generated values:"
echo "#    - apps/langfuse/secret.yaml"
echo "#    - apps/librechat/libre_chat_secret.yaml"
echo "#    - apps/datahub-pre/my_sql_secret.yaml"
echo "#    - apps/monitoring/kube-prom-stack.yaml"
echo "# 3. For Azure API key, get the value from your Azure Portal"
echo "# 4. DO NOT commit the updated secret files to version control"
echo "#"
echo "# For production deployments, consider using:"
echo "#   - AWS Secrets Manager: https://aws.amazon.com/secrets-manager/"
echo "#   - External Secrets Operator: https://external-secrets.io/"
echo "# ============================================================================"
