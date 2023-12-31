provider "oci" {
  region = var.region
}

provider "kubernetes" {
  config_path = "../outputs/kubectl-k8s-config.prod"
}

provider "helm" {
  kubernetes {
    config_path = "../outputs/kubectl-k8s-config.prod"
  }

}

module "base-install" {
    source = "../modules/base_install"

    deployment_env = "prod"

    compartment_id = var.compartment_id
    region = var.region
    ssh_public_key = var.ssh_public_key


    k8s_version = var.k8s_version
    k8s_node_config= var.k8s_node_config
    k8s_node_pool_size = var.k8s_node_pool_size

    create_bastion = var.create_bastion
    bastion_config=var.bastion_config

    ingress_email_issuer = var.ingress_email_issuer

    ingress_hosts = var.ingress_hosts

    tenancy_ocid = var.tenancy_ocid

}

