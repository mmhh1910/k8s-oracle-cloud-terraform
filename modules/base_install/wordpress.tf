resource "oci_core_public_ip" "wp_ip" {
    compartment_id = var.compartment_id
    lifetime       = "RESERVED"
    display_name = "k8s_wordpress_public_ip"
  }


resource "helm_release" "wordpress" {
  name       = "wordpress"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "wordpress"

  
  set {
    name  = "service.loadBalancerIP"
    value = oci_core_public_ip.wp_ip.ip_address 
  }

  values = [
    "${file("${path.module}/wordpress-values.yaml")}"
  ]
}

