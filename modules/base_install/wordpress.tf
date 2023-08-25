

# resource "helm_release" "wordpress" {
#   name       = "wordpress"

#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "wordpress"

  
#   set {
#     name  = "service.loadBalancerIP"
#     value = oci_core_public_ip.wp_ip.ip_address 
#   }

#   values = [
#     "${file("${path.module}/wordpress-values.yaml")}"
#   ]
# }

