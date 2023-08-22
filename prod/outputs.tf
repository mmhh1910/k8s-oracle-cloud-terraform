output "compartment-name" {
  value = module.base-install.compartment-name
}

output "compartment-id" {
  value = module.base-install.compartment-id
}

output "k8s-cluster-id" {
  value = module.base-install.k8s-cluster-id
}

output "public_subnet_id" {
  value = module.base-install.public_subnet_id
}

output "private_subnet_id" {
  value = module.base-install.private_subnet_id
}

output "node_pool_id_arm64" {
  value = module.base-install.node_pool_id_arm64
}

output "bastion_ip" {
  value  = module.base-install.bastion_ip
}


output "wp_ip" {
  value = module.base-install.wp_ip
}