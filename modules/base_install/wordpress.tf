resource "oci_core_public_ip" "wp_ip" {
    #Required
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


# data "external" "wp_ip" {
#   depends_on = [null_resource.kubectl-k8s-config-generation, helm_release.wordpress ]

#   program = ["kubectl","--kubeconfig","${path.root}/../outputs/kubectl-k8s-config.${var.deployment_env}","get","svc","--namespace","default","wordpress","-o","json"]
# }

