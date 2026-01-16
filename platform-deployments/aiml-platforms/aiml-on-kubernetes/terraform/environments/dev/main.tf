terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }

  required_version = ">= 1.2.0"
  
  backend "s3" {
    bucket         = "placeholder"
    key            = "placeholder"
    region         = "placeholder"
    encrypt        = true
    use_lockfile   = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

module "baseline_environment_network" {
  source = "../../modules/base-network"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
}

module "eks" {
  source = "../../modules/eks"
  
  cluster_name    = var.eks_cluster_name
  vpc_id          = module.baseline_environment_network.vpc_id
  subnet_ids      = module.baseline_environment_network.vpc_private_subnet_ids
  admin_role_arn  = var.eks_admin_role_arn
  vpc_cidr = module.baseline_environment_network.vpc_cidr
  eks_addon_version_efs_csi_driver = "v2.1.8-eksbuild.1"
}

provider "helm" {

  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
  }
}

provider "kubernetes" {

  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    command     = "aws"
  }
}


# with EKS auto mode, don't need to use AWS Load Balancer Controller 
# instead create ingress class



module "argocd" {
  source = "../../modules/argocd"

  eks_cluster_endpoint = module.eks.cluster_endpoint
  eks_cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  eks_cluster_name = module.eks.cluster_name
  certificate_arn = var.certificate_arn
  domain = var.domain
  load_balancer_group_name = "grindstone-ingress"
  route53_zone_id = var.route53_zone_id

  providers = {
    kubernetes = kubernetes
    helm = helm
  }
}

module "ecr" {
  source = "../../modules/ecr"
  ecr_repo_name = "grindstone-app"
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
