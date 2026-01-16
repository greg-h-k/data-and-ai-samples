# ============================================================================
# RStudio Server Terraform Variables
# ============================================================================
# IMPORTANT: Update ALL values below before running terraform apply!
# The values shown are examples only and will NOT work in your AWS account.
# ============================================================================

# AWS Region to deploy resources
# Default: eu-west-1 (change to your preferred region)
region = "eu-west-1"

# VPC CIDR block for the new VPC
# Ensure this doesn't conflict with existing networks in your account
vpc_cidr = "10.1.0.0/16"

# AMI ID for RStudio Server
# YOU MUST UPDATE THIS: Build your own AMI using Packer (see ../image/ directory)
# This example AMI only exists in the original account and will NOT work for you
rstudio_server_ami = "ami-XXXXXXXXXXXX"  # REPLACE WITH YOUR AMI ID

# EC2 instance type for RStudio Server
# t3.medium provides 2 vCPUs and 4 GB RAM (suitable for demos)
# Adjust based on your workload requirements
rstudio_server_instance_type = "t3.medium"

# EC2 Key Pair name for emergency SSH access
# YOU MUST UPDATE THIS: Use the name of an existing key pair in your AWS account
# The key pair must exist in the same region specified above
instance_key_name = "YOUR_KEY_PAIR_NAME"  # REPLACE WITH YOUR KEY PAIR NAME