# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Metrics Server variables
variable "metrics_server_enabled" {
  default     = true
  description = "Enable Metrics Server for Metrics, HPA, VPA and Cluster Autoscaler"
}

# Metrics Server for the HPA
## https://github.com/kubernetes-sigs/metrics-server/blob/master/charts/metrics-server/README.md
## https://artifacthub.io/packages/helm/metrics-server/metrics-server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.11.0"
  namespace  = "kube-system" # kubernetes_namespace.cluster_tools.id # Workaround to run on 1.24
  wait       = false

  set {
    name  = "args"
    value = "{--kubelet-insecure-tls,--kubelet-preferred-address-types=InternalIP}"
  }

  count = var.metrics_server_enabled ? 1 : 0
}