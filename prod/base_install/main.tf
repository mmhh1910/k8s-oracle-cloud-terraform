provider "oci" {
  region = var.region
}


data "oci_identity_compartment" "compartment" {
	#Required
	id = var.compartment_id
}

module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.1.0"

  compartment_id = var.compartment_id
  region         = var.region

  internet_gateway_route_rules = null
  local_peering_gateways       = null
  nat_gateway_route_rules      = null

  vcn_name      = "k8s-vcn"
  vcn_dns_label = "k8svcn"
  vcn_cidrs     = ["10.0.0.0/16"]

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
}

resource "oci_core_security_list" "private_subnet_sl" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name = "k8s-private-subnet-sl"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/24"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 31600
      max = 31600
    }
  }
}

resource "oci_core_security_list" "public_subnet_sl" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id

  display_name = "k8s-public-subnet-sl"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  
  egress_security_rules {
    stateless        = false
    destination      = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      min = 31600
      max = 31600
    }
  }

  egress_security_rules {
    stateless        = false
    destination      = "10.0.1.0/24"
    destination_type = "CIDR_BLOCK"
    protocol         = "6"
    tcp_options {
      min = 10256
      max = 10256
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.create_bastion ? "0.0.0.0/0" : "10.0.1.0/24"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Source is 0.0.0.0/0 if TF variable 'create_bastion' is true, otherwise set to 10.0.1.0/24 (private subnet)"

    tcp_options {
      max = 22
      min = 22
    }
  } 

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_subnet" "vcn_private_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.1.0/24"

  route_table_id             = module.vcn.nat_route_id
  security_list_ids          = [oci_core_security_list.private_subnet_sl.id]
  display_name               = "k8s-private-subnet"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_subnet" "vcn_public_subnet" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  cidr_block     = "10.0.0.0/24"

  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public_subnet_sl.id]
  display_name      = "k8s-public-subnet"
}

resource "oci_containerengine_cluster" "k8s_cluster" {
  compartment_id = var.compartment_id
  kubernetes_version = var.k8s_version
  name               = "k8s-cluster"
  vcn_id             = module.vcn.vcn_id

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.vcn_public_subnet.id
  }

  options {
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled               = false
    }
    kubernetes_network_config {
      pods_cidr     = "10.244.0.0/16"
      services_cidr = "10.96.0.0/16"
    }
    service_lb_subnet_ids = [oci_core_subnet.vcn_public_subnet.id]
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

locals {
  # Gather a list of availability domains for use in configuring placement_configs
  azs = data.oci_identity_availability_domains.ads.availability_domains[*].name
}

data "oci_core_images" "latest_image_arm64" {
  compartment_id = var.compartment_id
  operating_system = var.k8s_node_config.operating_system
  operating_system_version = var.k8s_node_config.operating_system_version
  shape = var.k8s_node_config.shape
}


resource "oci_containerengine_node_pool" "k8s_node_pool_arm64" {
  cluster_id         = oci_containerengine_cluster.k8s_cluster.id
  compartment_id = var.compartment_id
  kubernetes_version = var.k8s_version
  name               = "k8s-node-pool_arm64"
  node_config_details {
    dynamic placement_configs {
      for_each = local.azs
      content {
        availability_domain = placement_configs.value
        subnet_id           = oci_core_subnet.vcn_private_subnet.id
      }
    }
    size = var.k8s_node_pool_size
  }

  node_shape = var.k8s_node_config.shape

  node_shape_config {
        memory_in_gbs = var.k8s_node_config.memory_in_gbs
        ocpus = var.k8s_node_config.ocpus
    }

  node_source_details {
    image_id    = data.oci_core_images.latest_image_arm64.images.0.id
    source_type = "image"
  }

  initial_node_labels {
    key   = "name"
    value = "k8s-cluster"
  }

  ssh_public_key = var.ssh_public_key
}


data "oci_core_images" "latest_image_arm64_bastion" {
  compartment_id = var.compartment_id
  operating_system = var.bastion_config.operating_system
  operating_system_version = var.bastion_config.operating_system_version
  shape = var.bastion_config.shape
}


resource "oci_core_instance" "k8s_bastion" {
	display_name = "k8s_bastion"
  count = var.create_bastion ? 1 : 0
  availability_domain = local.azs[0]
  compartment_id = var.compartment_id
	create_vnic_details {
		assign_private_dns_record = "false"
		assign_public_ip = "true"
		subnet_id = oci_core_subnet.vcn_public_subnet.id
	}
	metadata = {
		"ssh_authorized_keys" = var.ssh_public_key
	}
	shape = var.bastion_config.shape
	source_details {
    source_id    = data.oci_core_images.latest_image_arm64_bastion.images.0.id
    source_type = "image"
	}
  shape_config {
        memory_in_gbs = var.bastion_config.memory_in_gbs
        ocpus = var.bastion_config.ocpus
    }

}


resource "oci_identity_policy" "csi_fss" {
    compartment_id = var.compartment_id
    description = "CSI volume plugin to create and manage File Storage resources."
    name = "csi_fss"
    statements = [
        "ALLOW any-user to manage file-family in compartment ${data.oci_identity_compartment.compartment.name} where request.principal.type = 'cluster'", 
        "ALLOW any-user to use virtual-network-family in compartment ${data.oci_identity_compartment.compartment.name} where request.principal.type = 'cluster'"
        ]
}
