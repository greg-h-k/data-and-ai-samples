variable "eks_cluster_endpoint" {
  type = string
}

variable "eks_cluster_certificate_authority_data" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "domain" {
  type = string
  description = "Domain endpoint. Argocd subdomain created under this."
}

variable "load_balancer_group_name" {
  type = string
  description = "Common group name to apply to ingress annotation to re-use the load balancer"
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID where the alias record will be registered"
  type        = string
}