# Copyright (c) 2022 Oracle and/or its affiliates. All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
# 

# Cert Manager variables
variable "cert_manager_enabled" {
  default     = true
  description = "Enable x509 Certificate Management"
}

module "cert-manager" {
  source = "./modules/cert-manager"

  # Helm Release variables
  chart_namespace      = "default"
  chart_repository     = "https://charts.jetstack.io"
  chart_version        = "1.12.0"
  ingress_email_issuer = var.ingress_email_issuer

  count = var.cert_manager_enabled ? 1 : 0
}