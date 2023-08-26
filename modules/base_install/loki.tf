variable "loki_enabled" {
  default     = true
  description = "Enable loki"
}


resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.11"
  namespace  = "default"
  wait       = false
  
  values = [
    <<EOF
loki:
  securityContext:
    runAsNonRoot: false
    runAsUser: 0
  enabled: true
  persistence:
    enabled: true
    size: 1Gi
EOF
  ]

  count = var.loki_enabled ? 1 : 0
}