terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace = "argocd"
  create_namespace = true
}

resource "kubernetes_manifest" "argocd-service" {
  depends_on = [ helm_release.argocd ]
  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "annotations" = {
        "alb.ingress.kubernetes.io/backend-protocol-version" = "GRPC"
      }
      "labels" = {
        "app" = "argogrpc"
      }
      "name"      = "argogrpc"
      "namespace" = "argocd"
    }
    "spec" = {
      "ports" = [
        {
          "name"       = "443"
          "port"       = 443
          "protocol"   = "TCP"
          "targetPort" = "8080"
        },
      ]
      "selector" = {
        "app.kubernetes.io/name" = "argocd-server"
      }
      "sessionAffinity" = "None"
      "type" = "NodePort"
    }
  }
}

resource "kubernetes_manifest" "argocd-ingress" {
  depends_on = [ kubernetes_manifest.argocd-service ]
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "annotations" = {
        "alb.ingress.kubernetes.io/backend-protocol" = "HTTPS"
        "alb.ingress.kubernetes.io/conditions.argogrpc" = "[{\"field\":\"http-header\",\"httpHeaderConfig\":{\"httpHeaderName\": \"Content-Type\", \"values\":[\"application/grpc\"]}}]"
        "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTPS\":443}]"
        "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"      = "ip"
        "alb.ingress.kubernetes.io/certificate-arn" = var.certificate_arn
      }
      "name"      = "argocd"
      "namespace" = "argocd"
    }
    "spec" = {
      "ingressClassName" = "alb"
      "rules" = [
        {
          "host" = "argocd.${var.domain}"
          "http" = {
            "paths" = [
              {
                "backend" = {
                  "service" = {
                    "name" = "argogrpc"
                    "port" = {
                      "number" = 443
                    }
                  }
                }
                "path"     = "/"
                "pathType" = "Prefix"
              },
              {
                "backend" = {
                  "service" = {
                    "name" = "argocd-server"
                    "port" = {
                      "number" = 443
                    }
                  }
                }
                "path"     = "/"
                "pathType" = "Prefix"
              }
            ]
          }
        }
      ]
      "tls" = [
        {
          "hosts" = [
            "argocd.${var.domain}"
          ]
        }
      ]
    }
  }
}

# Get ALB details after ingress creates it
data "aws_lb" "argocd_alb" {
  tags = {
    "eks:eks-cluster-name" = var.eks_cluster_name
  }
  
  depends_on = [kubernetes_manifest.argocd-ingress]
}

# Create Route53 alias record
resource "aws_route53_record" "argocd-alias" {
  zone_id = var.route53_zone_id
  name    = "argocd.${var.domain}"
  type    = "A"

  alias {
    name                   = data.aws_lb.argocd_alb.dns_name
    zone_id                = data.aws_lb.argocd_alb.zone_id
    evaluate_target_health = true
  }
}