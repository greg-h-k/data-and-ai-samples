data "aws_caller_identity" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name    = var.cluster_name
  kubernetes_version = "1.33"

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_public_access = true
  enable_irsa = true

  # eks_managed_node_groups = {
  #   main = {
  #     min_size     = 2
  #     max_size     = 10
  #     desired_size = 6

  #     instance_types = ["m6i.xlarge"]
  #     capacity_type  = "ON_DEMAND"

  #     iam_role_additional_policies = { 
  #       # to allow EBS auto creation by EBS controller 
  #       AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy" 
  #     }
  #   }
  # }

  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  access_entries = {
    admin = {
      kubernetes_groups = []
      principal_arn     = var.admin_role_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
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

###
# EKS AUTO MODE
# with EKS auto mode don't need to configure AWS ALB and EBS controller etc. 
# definte the classes and auto does the rest 
###

# INGRESS 
# https://docs.aws.amazon.com/eks/latest/userguide/auto-configure-alb.html
resource "kubernetes_manifest" "alb_ingress_class_params" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "IngressClassParams"
    metadata = {
      name = "alb"
    }
    spec = {
      scheme = "internet-facing"
    }
  }
}

resource "kubernetes_manifest" "alb_ingress_class" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "IngressClass"
    metadata = {
      name = "alb"
    }
    spec = {
      controller = "eks.amazonaws.com/alb"
      parameters = {
        apiGroup = "eks.amazonaws.com"
        kind     = "IngressClassParams"
        name     = "alb"
      }
    }
  }
}

# EBS provisioner 
# https://docs.aws.amazon.com/eks/latest/userguide/create-storage-class.html
resource "kubernetes_manifest" "ebs_storage_class" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "ebs"
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "true"
      }
    }
    provisioner = "ebs.csi.eks.amazonaws.com"
    volumeBindingMode = "WaitForFirstConsumer"
    parameters = {
      type = "gp3"
      encrypted = true
    }
  }
}

## NodeClass
# resource "kubernetes_manifest" "node_class" {
#   manifest = {
#     apiVersion = "eks.amazonaws.com/v1"
#     kind       = "NodeClass"
#     metadata = {
#       name = "private-gpu"
#     }
#     spec = {
#       # subnetSelectorTerms = [
#       #   {
#       #     tags = {
#       #       Name = "*private*"
#       #       # kubernetes.io/role/internal-elb = "1"
#       #     }
#       #   }
#       # ]
#       # securityGroupSelectorTerms = [
#       #   {
#       #     tags = {
#       #       Name = "intra-security-group"
#       #     }
#       #   }
#       # ]
#       ephemeralStorage = {
#         size = "160Gi"
#       }
#     }
#   }
# }

## Node pool 
# https://docs.aws.amazon.com/eks/latest/userguide/create-node-pool.html
resource "kubernetes_manifest" "node_pool" {
  # depends_on = [ kubernetes_manifest.node_class ]
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = "private-gpu-pool"
    }
    spec = {
      template = {
        metadata = {
          labels = {
            "project" = "grindstone"
          }
        }
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind =  "NodeClass"
            name = "default"
          }
          requirements = [
            {
              key = "eks.amazonaws.com/instance-category"
              operator = "In"
              values = ["g"]
            },
            {
              key = "eks.amazonaws.com/instance-family"
              operator = "In"
              values = ["g4dn"]
            },
            {
              key = "eks.amazonaws.com/instance-cpu"
              operator = "In"
              values = ["8", "16"]
            },
            {
              key = "karpenter.sh/capacity-type"
              operator = "In"
              values = ["on-demand"]
            },
            {
              key = "kubernetes.io/arch"
              operator = "In"
              values = ["amd64"]
            },
          ]
        }
      }
      limits = {
        cpu = "32"
        memory = "160Gi"
      }
    }
  }
}



###
# PRE EKS AUTO MODE
###

# module "aws_load_balancer_controller_irsa_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.58.0"

#   role_name = "aws-load-balancer-controller-role"

#   attach_load_balancer_controller_policy = true

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#     }
#   }
# }

# resource "helm_release" "aws_load_balancer_controller" {
#   name = "aws-load-balancer-controller"

#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.13.3"

#   set {
#     name  = "replicaCount"
#     value = 1
#   }

#   set {
#     name  = "clusterName"
#     value = module.eks.cluster_name
#   }

#   set {
#     name  = "serviceAccount.name"
#     value = "aws-load-balancer-controller"
#   }

#   set {
#     name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
#     value = module.aws_load_balancer_controller_irsa_role.iam_role_arn
#   }
# }



# EFS Storage class provisioning
# module "vpc_cni_irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.58.0"

#   role_name_prefix                   = "VPC-CNI-IRSA"
#   attach_vpc_cni_policy              = true
#   vpc_cni_enable_ipv4                = true
#   attach_ebs_csi_policy              = true
#   attach_efs_csi_policy = true

#   oidc_providers = {
#     efs = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:efs-csi-controller-sa"]
#     }
#   }
# }

# resource "aws_eks_addon" "aws_efs_csi_driver" {
#   count = var.eks_addon_version_efs_csi_driver != null ? 1 : 0

#   cluster_name  = module.eks.cluster_name
#   addon_name    = "aws-efs-csi-driver"
#   addon_version = var.eks_addon_version_efs_csi_driver

#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "OVERWRITE"

#   service_account_role_arn = module.vpc_cni_irsa.iam_role_arn

#   configuration_values = jsonencode({
#     controller = {
#       tolerations : [
#         {
#           key : "system",
#           operator : "Equal",
#           value : "owned",
#           effect : "NoSchedule"
#         }
#       ]
#     }
#   })

#   preserve = true

#   tags = {
#     "eks_addon" = "aws-ebs-csi-driver"
#   }
# }

# resource "aws_security_group" "efs" {
#   name        = "${var.cluster_name}-efs-sg"
#   description = "Allow VPC traffic"
#   vpc_id      = var.vpc_id

#   ingress {
#     description      = "nfs"
#     from_port        = 2049
#     to_port          = 2049
#     protocol         = "TCP"
#     cidr_blocks      = [var.vpc_cidr]
#   }
# }

# resource "aws_efs_file_system" "kube" {
#   creation_token = "eks-efs"
#   encrypted      = true
#   tags           = merge({
#                     "eks_addon" = "aws-efs-csi-driver"
#                     })
# }

# resource "aws_efs_mount_target" "mount" {
#     file_system_id  = aws_efs_file_system.kube.id
#     subnet_id       = each.key
#     for_each        = toset(var.subnet_ids)
#     security_groups = [aws_security_group.efs.id]
# }

# resource "kubernetes_manifest" "efs_storage_class" {
#   manifest = {
#     apiVersion = "storage.k8s.io/v1"
#     kind       = "StorageClass"
#     metadata = {
#       name = "efs-sc"
#       # annotations = {
#       #   "storageclass.kubernetes.io/is-default-class" = "true"
#       # }
#     }
#     provisioner = "efs.csi.aws.com"
#     parameters = {
#       provisioningMode = "efs-ap"
#       fileSystemId     = aws_efs_file_system.kube.id
#       directoryPerms   = "755"
#     }
#   }

#   depends_on = [
#     aws_efs_file_system.kube
#   ]
# }

# # EBS addon
# module "ebs-driver-irsa" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.58.0"

#   role_name_prefix                   = "ebs-csi-driver"
#   attach_ebs_csi_policy              = true

#   oidc_providers = {
#     ebs = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }
# }

# resource "aws_eks_addon" "aws_ebs_csi_driver" {

#   cluster_name  = module.eks.cluster_name
#   addon_name    = "aws-ebs-csi-driver"
#   addon_version = "v1.45.0-eksbuild.2"
#   service_account_role_arn = module.ebs-driver-irsa.iam_role_arn
# }

# resource "kubernetes_manifest" "ebs_storage_class" {
#   manifest = {
#     apiVersion = "storage.k8s.io/v1"
#     kind       = "StorageClass"
#     volumeBindingMode = "WaitForFirstConsumer"
#     metadata = {
#       name = "ebs-sc"
#       annotations = {
#         "storageclass.kubernetes.io/is-default-class" = "true"
#       }
#     }
#     provisioner = "ebs.csi.aws.com"
#     parameters = {
#       type = "gp3"
#     }
#   }

#   depends_on = [
#     aws_eks_addon.aws_ebs_csi_driver
#   ]
# }

