variable "tenancy_ocid" {
  type        = string
  description = "The tenanany id."
}


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


variable "k8s_node_pool_size" {
  type = number
  default = 2
  description = "Number of nodes in the k8s node-pool"
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

variable "ingress_email_issuer" {
  default     = "no-reply@example.cloud"
  description = "You must replace this email address with your own. The certificate provider will use this to contact you about expiring certificates, and issues related to your account."
}

variable "ingress_hosts" {
  default     = ""
  description = "Enter a valid full qualified domain name (FQDN). You will need to map the domain name to the EXTERNAL-IP address on your DNS provider (DNS Registry type - A). If you have multiple domain names, include separated by comma. e.g.: mushop.example.com,catshop.com"
}
