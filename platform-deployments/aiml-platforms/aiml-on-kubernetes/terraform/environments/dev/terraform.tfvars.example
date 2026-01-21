# ============================================================================
# AI/ML Platform Terraform Variables
# ============================================================================
# IMPORTANT: Update ALL values below before deployment!
# These are examples only and will NOT work in your AWS account.
# ============================================================================

# AWS Region to deploy resources
# Change to your preferred region (e.g., us-east-1, us-west-2, eu-west-1)
aws_region = "us-east-1"

# VPC Configuration
# Change to your naming convention
vpc_name = "aiml-platform-vpc"

# VPC CIDR block - ensure no conflicts with existing networks
vpc_cidr = "10.2.0.0/16"

# EKS Cluster Configuration
# Change to your cluster name
eks_cluster_name = "aiml-platform-cluster"

# IAM Admin Role ARN - YOU MUST UPDATE THIS
# This role will have admin access to the EKS cluster
# Format: arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE_NAME
# Example: arn:aws:iam::123456789012:role/Admin
eks_admin_role_arn = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ADMIN_ROLE"

# ACM Certificate ARN - YOU MUST UPDATE THIS
# Must be in the same region as deployment
# Must cover your domain (wildcard recommended: *.your-domain.com)
# Format: arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERT_ID
# Example: arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012
certificate_arn = "arn:aws:acm:YOUR_REGION:YOUR_ACCOUNT_ID:certificate/YOUR_CERT_ID"

# Domain Configuration - YOU MUST UPDATE THIS
# Must match your Route 53 hosted zone
# All applications will be accessible at subdomains of this domain
# Example: your-domain.example.com
domain = "your-domain.example.com"

# Route 53 Hosted Zone ID - YOU MUST UPDATE THIS
# Get from Route 53 console for your hosted zone
# Format: Z followed by alphanumeric characters
# Example: Z1234567890ABC
route53_zone_id = "YOUR_ZONE_ID"
