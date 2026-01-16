variable "vpc_name" {
  type = string
  description = "Name for the VPC"
}

variable "aws_region" {
  type = string
  description = "The deployment region"
}

variable "vpc_cidr" {
  type = string
  description = "A CIDR address range to use for the VPC, must not conflict with existing VPC ranges"
}

variable "eks_cluster_name" {
  type = string
  description = "Name of the EKS cluster"
}

variable "eks_admin_role_arn" {
  type = string
  description = "ARN of the IAM role to grant admin access to the cluster"
}

variable "certificate_arn" {
  type = string
}

variable "domain" {
  type = string
  description = "Base domain"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID where the alias record will be registered"
  type        = string
}