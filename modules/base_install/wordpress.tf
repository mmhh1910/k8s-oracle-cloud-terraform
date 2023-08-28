variable "wordpress_enabled" {
  default     = true
  description = "Enable wordpress"
}


resource "helm_release" "wordpress" {
  name       = "wordpress"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "wordpress"

  
  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  values = [
    "${file("${path.module}/wordpress-values.yaml")}"
  ]
  count = var.wordpress_enabled ? 1 : 0
}


resource "kubernetes_ingress_v1" "wordpress" {
  wait_for_load_balancer = true
  metadata {
    name        = "wordpress"
    namespace   = "default"
    annotations = local.ingress_nginx_annotations
  }
  spec {
    ingress_class_name = "nginx"
    rule {
      host ="wordpress.xn--marcusmnnig-xfb.de"
      http {
        path {
          backend {
            service {
              name = "wordpress"
              port {
                number = 80
              }
            }
          }
        }
      }
    }


    tls {
      secret_name = "wordpress-${var.ingress_cluster_issuer}-tls"
      hosts       = ["wordpress.xn--marcusmnnig-xfb.de"]
    }
  }
  depends_on = [helm_release.ingress_nginx, helm_release.wordpress]

  count = (var.ingress_nginx_enabled && var.wordpress_enabled) ? 1 : 0
}
