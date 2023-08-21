
variable "compartment_id" {
  type        = string
  description = "The compartment id to create the resources in. Has to be pre-created"
}

variable "region" {
  type        = string
  description = "The region to provision the resources in"
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key to use for connecting to the worker nodes"
  sensitive = true
}


variable "k8s_version" {
  type        = string
  default = "v1.27.2"
  description = "K8s version"
}

variable "k8s_node_config" {
  type = map
  default = {
      memory_in_gbs = 6, 
      ocpus = 1, 
      shape= "VM.Standard.A1.Flex" 
      operating_system ="Oracle Linux"
      operating_system_version = "7.9"        
      }
  description = "Settings for the node compute instances."
}


variable "create_bastion" {
  type        = bool
  description = "If set to true, a bastion host will be created"
  default = false
}

variable "bastion_config" {
  type = map
  default = {
      memory_in_gbs = 2, 
      ocpus = 1, 
      shape= "VM.Standard.A1.Flex" 
      operating_system ="Oracle Linux"
      operating_system_version = "7.9"        
      }
  description = "Settings for the bastion compute instances."
}
