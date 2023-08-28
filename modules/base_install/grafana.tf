variable "grafana_enabled" {
  default     = true
  description = "Enable Grafana Dashboards. Includes example dashboards and Prometheus, OCI Logging and OCI Metrics datasources"
}


resource oci_identity_dynamic_group export_grafana_dg {
  compartment_id = var.tenancy_ocid
  description = "grafana dg"
  matching_rule = "Any {All {instance.compartment.id = '${var.compartment_id}'}}"
  name          = "grafana_dg"
  count = var.grafana_enabled ? 1 : 0
}

resource oci_identity_policy export_grafana_policy {
  compartment_id = var.tenancy_ocid
  description = "grafana_policy"
  name = "grafana_policy"
  statements = [
    "allow dynamicgroup grafana_dg to read metrics in tenancy",
    "allow dynamicgroup grafana_dg to read compartments in tenancy",
  ]
  count = var.grafana_enabled ? 1 : 0
}

# Grafana Helm chart
## https://github.com/grafana/helm-charts/blob/main/charts/grafana/README.md
## https://artifacthub.io/packages/helm/grafana/grafana
resource "helm_release" "grafana" {

  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "6.56.5"
  namespace  = "default"
  wait       = false
  # set {
  #   name  = "grafana\\.ini.server.root_url"
  #   value = "%(protocol)s://%(domain)s:%(http_port)s/grafana"
  #   type  = "string"
  # }

  # set {
  #   name  = "grafana\\.ini.server.serve_from_sub_path"
  #   value = "true"
  # }

  values = [
    <<EOF
initChownData:
  enabled: false
securityContext:
  runAsNonRoot: false
  runAsUser: 0
envFromSecret: grafana-dashboard-secrets
dashboards:
  default:
    k8s-cluster:
      gnetId: 7249
      revision: 1
      datasource: Prometheus
    k8s-cluster-metrics:
      gnetId: 11663
      revision: 1
      datasource: Prometheus
    k8s-cluster-metrics-simple:
      gnetId: 6417
      revision: 1
      datasource: Prometheus
    k8s-pods-monitoring:
      gnetId: 13498
      revision: 1
      datasource: Prometheus
    k8s-memory:
      gnetId: 13421
      revision: 1
      datasource: Prometheus
    k8s-networking:
      gnetId: 12658
      revision: 1
      datasource: Prometheus
    k8s-cluster-autoscaler:
      gnetId: 3831
      revision: 1
      datasource: Prometheus
    k8s-hpa:
      gnetId: 10257
      revision: 1
      datasource: Prometheus
    k8s-pods:
      gnetId: 6336
      revision: 1
      datasource: Prometheus
    spring-boot:
      gnetId: 12464
      revision: 2
      datasource: Prometheus
    nginx-ingress-controller:
      gnetId: 9614
      revision: 1
      datasource: Prometheus
    oci-compute:
      gnetId: 13596
      revision: 1
      datasource: Oracle Cloud Infrastructure Metrics
    oci-oke:
      gnetId: 13594
      revision: 1
      datasource: Oracle Cloud Infrastructure Metrics
dashboardProviders:
   dashboardproviders.yaml:
     apiVersion: 1
     providers:
     - name: 'default'
       orgId: 1
       folder: ''
       type: file
       disableDeletion: true
       editable: true
       options:
         path: /var/lib/grafana/dashboards/default
sidecar:
  datasources:
    enabled: true
    label: grafana_datasource
  dashboards:
    enabled: true
    label: grafana_dashboard
persistence:
  enabled: true
plugins:
  - oci-logs-datasource
  - oci-metrics-datasource
  - grafana-kubernetes-app
  - grafana-worldmap-panel
  - grafana-piechart-panel
  - btplc-status-dot-panel
datasources: 
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.default.svc.cluster.local
      access: proxy
      isDefault: false
      disableDeletion: true
      editable: false
    - name: Oracle Cloud Infrastructure Metrics
      type: oci-metrics-datasource
      access: proxy
      isDefault: false
      disableDeletion: true
      editable: true
      jsonData:
        tenancyOCID: ${var.tenancy_ocid}
        defaultRegion: ${var.region}
        environment: "OCI Instance"
    - name: Oracle Cloud Infrastructure Logs
      type: oci-logs-datasource
      access: proxy
      isDefault: false
      disableDeletion: true
      editable: true
      jsonData:
        tenancyOCID: ${var.tenancy_ocid}
        defaultRegion: ${var.region}
        environment: "OCI Instance"
EOF
  ]

  count = var.grafana_enabled ? 1 : 0
}

## Grafana Ingress
resource "kubernetes_ingress_v1" "grafana" {
  wait_for_load_balancer = true
  metadata {
    name        = "grafana"
    namespace   = "default"
    annotations = local.ingress_nginx_annotations
  }
   spec {
    ingress_class_name = "nginx"
    rule {
      host ="grafana.xn--marcusmnnig-xfb.de"
      http {
        path {
          backend {
            service {
              name = "grafana"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      secret_name = "grafana-${var.ingress_cluster_issuer}-tls"
      hosts       = ["grafana.xn--marcusmnnig-xfb.de"]
    }
  }
  depends_on = [helm_release.ingress_nginx, helm_release.grafana]

  count = (var.grafana_enabled && var.ingress_nginx_enabled) ? 1 : 0
}

## Kubernetes Secret: Grafana Admin Password
data "kubernetes_secret" "grafana" {
  metadata {
    name      = "grafana"
    namespace = "default"
  }
  depends_on = [helm_release.grafana]

  count = var.grafana_enabled ? 1 : 0
}

locals {
  grafana_admin_password = var.grafana_enabled ? data.kubernetes_secret.grafana.0.data.admin-password : "Grafana_Not_Deployed"
}

output "grafana_admin_password" {
  value     = var.grafana_enabled ? local.grafana_admin_password : null
  sensitive = true
}




