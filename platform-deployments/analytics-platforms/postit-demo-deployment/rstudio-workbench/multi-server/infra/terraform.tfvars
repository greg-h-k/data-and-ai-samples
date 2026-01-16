# ============================================================================
# RStudio Workbench Multi-Server Terraform Variables
# ============================================================================
# IMPORTANT: Update ALL values below before running terraform apply!
# The values shown are examples only and will NOT work in your AWS account.
# ============================================================================

# AWS Region to deploy resources
# Default: eu-west-1 (change to your preferred region)
# All resources (VPC, EC2, RDS, EFS) will be created in this region
region = "eu-west-1"

# AMI ID for RStudio Workbench
# YOU MUST UPDATE THIS: Build your own AMI using Packer (see ../image/ directory)
# This example AMI only exists in the original account and will NOT work for you
rstudio_workbench_ami = "ami-XXXXXXXXXXXX"  # REPLACE WITH YOUR AMI ID

# EC2 Key Pair name for emergency SSH access
# YOU MUST UPDATE THIS: Use the name of an existing key pair in your AWS account
# The key pair must exist in the same region specified above
ec2_key_name = "YOUR_KEY_PAIR_NAME"  # REPLACE WITH YOUR KEY PAIR NAME

# VPC CIDR block for the new VPC
# Ensure this doesn't conflict with existing networks in your account
# Note: Different from RStudio Server (10.1.0.0/16) to avoid conflicts
vpc_cidr = "10.2.0.0/16"