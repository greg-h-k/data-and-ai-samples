variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the nodes/node groups will be provisioned"
  type        = list(string)
}

variable "admin_role_arn" {
  description = "ARN of the IAM role to grant admin access to the cluster"
  type        = string
}

variable "eks_addon_version_efs_csi_driver" {
  type = string
}

variable "vpc_cidr" {
  type = string
  description = "VPC CIDR range for use with EFS security group"
}