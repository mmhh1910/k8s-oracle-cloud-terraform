output "compartment-name" {
  value = data.oci_identity_compartment.compartment.name
}

output "compartment-id" {
  value = data.oci_identity_compartment.compartment.id
}

output "k8s-cluster-id" {
  value = oci_containerengine_cluster.k8s_cluster.id
}

output "public_subnet_id" {
  value = oci_core_subnet.vcn_public_subnet.id
}

output "private_subnet_id" {
  value = oci_core_subnet.vcn_private_subnet.id
}

output "node_pool_id_arm64" {
  value = oci_containerengine_node_pool.k8s_node_pool_arm64.id
}

output "bastion_ip" {
  value = var.create_bastion ? oci_core_instance.k8s_bastion[0].public_ip : "Bastion not created"
}

output "wp_ip" {
  value =  oci_core_public_ip.wp_ip.ip_address
}