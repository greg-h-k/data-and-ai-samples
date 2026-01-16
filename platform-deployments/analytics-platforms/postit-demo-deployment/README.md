# Posit Analytics Platform Deployment

> **Services:** Amazon EC2, Amazon EFS, Amazon RDS Aurora, RStudio Server, Shiny Server, Posit Workbench
> **Complexity:** Intermediate
> **Last Updated:** 2026-01-16

Automated deployment of [Posit](https://posit.co/) data science and analytics platforms on AWS, including RStudio Server (open source) and Posit Workbench (commercial) configurations.

## ⚠️ Important Security Notice

**These are demonstration deployments for development and testing purposes.**

Before deploying to production environments, you must:
- Review and harden all security group rules
- Enable VPC Flow Logs and CloudTrail
- Implement proper backup and disaster recovery procedures
- Configure RDS final snapshots and backup retention
- Replace all placeholder credentials and AMI IDs
- Enable encryption at rest for all data stores
- Implement proper authentication (SAML, OAuth, LDAP)
- Follow the principle of least privilege for IAM roles
- Conduct security scanning and penetration testing
- Review [Posit Workbench Admin Guide](https://docs.posit.co/ide/server-pro/) for production configurations

**DO NOT use example passwords or configurations shown in this demo in production.**

## Overview

### What This Platform Provides

[Posit](https://posit.co/) delivers open source and commercial software for data science and analytics workloads:

**Open Source Tools:**
- **RStudio Server** - Browser-based R IDE deployed on scalable EC2 infrastructure
- **Shiny Server** - Platform for sharing interactive R visualizations and dashboards

**Commercial Tools:**
- **Posit Workbench** - Enterprise-grade IDE with high availability, enhanced security, and team collaboration features

### Deployment Options

| Option | Description | Use Case | Path |
|--------|-------------|----------|------|
| **RStudio Server** | Single-node deployment with RStudio IDE and Shiny Server | Development, small teams, demos | [rstudio-server/](./rstudio-server/) |
| **Workbench Multi-Server** | High-availability deployment with load balancing, shared storage, and PostgreSQL backend | Production teams, mission-critical workloads | [rstudio-workbench/multi-server/](./rstudio-workbench/multi-server/) |

## Prerequisites

### AWS Requirements

1. **AWS Account** with permissions to create:
   - VPC, subnets, NAT gateways
   - EC2 instances and AMIs
   - IAM roles and policies
   - RDS Aurora clusters (for Workbench)
   - EFS file systems (for Workbench)
   - Secrets Manager secrets

2. **IAM Instance Profile** for Packer builds:
   - Must have `AmazonSSMManagedInstanceCore` policy attached
   - Default name expected: `SSMInstanceProfile`
   - Used for SSM Session Manager access during AMI builds

3. **EC2 Key Pair** in target region:
   - Required for emergency access to instances
   - You must update `instance_key_name` or `ec2_key_name` in `terraform.tfvars` files

### Local Tools

- **Packer** 1.8+ ([installation guide](https://www.packer.io/downloads))
- **Terraform** 1.0+ ([installation guide](https://www.terraform.io/downloads))
- **AWS CLI** 2.x configured with credentials ([installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **SSH client** with support for AWS Session Manager
- **Session Manager Plugin** for AWS CLI ([installation guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html))

### Before Deployment

Each deployment requires updating placeholder values:

1. **AMI IDs** - Build custom AMIs with Packer first, then update `terraform.tfvars`
2. **EC2 Key Pair Names** - Replace with your existing key pair name
3. **AWS Region** - Default is `eu-west-1`, change if needed
4. **VPC CIDR Blocks** - Adjust if conflicts with existing networks

**All placeholder values must be updated before running `terraform apply`.**

## Quick Start

### RStudio Server (Single Node)

1. Navigate to [rstudio-server/](./rstudio-server/)
2. Follow the detailed README for:
   - Building the AMI with Packer
   - Deploying infrastructure with Terraform
   - Configuring SSH access via Session Manager
   - Creating user accounts

### Posit Workbench (Multi-Server HA)

1. Navigate to [rstudio-workbench/multi-server/](./rstudio-workbench/multi-server/)
2. Follow the comprehensive README for:
   - Building the Workbench AMI
   - Deploying the high-availability infrastructure
   - Configuring shared database and storage
   - Setting up user authentication

## Architecture

### RStudio Server Architecture

```
Private Subnet (no public IPs)
    │
    ├─ EC2 Instance (t3.medium)
    │   ├─ RStudio Server (port 8787)
    │   └─ Shiny Server (port 3838)
    │
    └─ Access: SSH via AWS Systems Manager
```

### Workbench Multi-Server Architecture

```
┌────────────────────────────────────────┐
│  Load Balanced Workbench Nodes (2)    │
│  ├─ EC2 Instance 1 (t3.medium)        │
│  └─ EC2 Instance 2 (t3.medium)        │
└────────────────┬───────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
┌────────┐  ┌────────┐  ┌────────────┐
│  EFS   │  │  RDS   │  │ Secrets    │
│ Shared │  │ Aurora │  │ Manager    │
│Storage │  │Postgres│  │ (DB Pass)  │
└────────┘  └────────┘  └────────────┘
```

## Security Considerations

### Network Security

- **No Public IPs**: All EC2 instances deployed in private subnets
- **VPC Endpoints**: SSM access without internet gateway traversal
- **Security Groups**: Self-referencing for internal communication
- **Egress Filtering**: Review and restrict outbound traffic for production

### Access Control

- **SSM Session Manager**: SSH access without bastion hosts or key management
- **No Inbound Rules**: Security groups have no inbound rules from internet
- **IAM Roles**: Least privilege principles for EC2 instance profiles
- **Database IAM Auth**: Enabled for RDS (configure for production use)

### Data Protection

- **Encryption at Rest**: EBS volumes, EFS, and RDS encrypted by default
- **Secrets Management**: RDS master password managed by AWS Secrets Manager
- **IMDSv2**: Required for all EC2 instances (prevents SSRF attacks)


## Cost Considerations

Estimated costs for running these deployments (us-east-1 pricing):

| Component | RStudio Server | Workbench Multi-Server | Notes |
|-----------|----------------|------------------------|-------|
| EC2 Instances | ~$0.04/hr (t3.medium) | ~$0.08/hr (2× t3.medium) | On-demand pricing |
| NAT Gateway | ~$0.045/hr | ~$0.045/hr | Plus data transfer |
| EFS | N/A | ~$0.30/GB-month | Based on usage |
| RDS Aurora | N/A | ~$0.12/hr (0.5 ACU min) | Serverless v2 |
| **Est. Total** | **~$34/month** | **~$90-120/month** | Assumes low EFS usage |

**Important**: Delete resources when not in use to minimize costs. Follow cleanup instructions in each subdirectory's README.

## Cleanup

To avoid ongoing charges, follow the cleanup instructions in each deployment's README:

- [RStudio Server Cleanup](./rstudio-server/README.md#cleanup)
- [Workbench Multi-Server Cleanup](./rstudio-workbench/multi-server/README.md#cleanup-and-decommissioning)

**Critical**: Terraform destroy will delete the RDS database without a final snapshot by default. Back up any important data first.

## Further Reading

- [Posit Documentation](https://docs.posit.co/)
- [RStudio Server Admin Guide](https://docs.posit.co/ide/server-pro/)
- [Posit Workbench Admin Guide](https://docs.posit.co/ide/server-pro/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Systems Manager Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html) 