variable "location" {
  type        = string
  description = "Azure region where all resources will be provisioned."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
}

variable "vnet_cidr" {
  type        = string
  description = "Address space for the Azure Virtual Network."
}

variable "aks_node_vm_size" {
  type        = string
  description = "VM size for the AKS node pool."
}

variable "postgres_sku" {
  type        = string
  description = "SKU for the Azure Database for PostgreSQL Flexible Server."
}

variable "postgres_admin_username" {
  type        = string
  description = "Administrator username for the PostgreSQL Flexible Server."
}

variable "postgres_admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for the PostgreSQL Flexible Server."
}

variable "dns_label" {
  type        = string
  description = "DNS label prefix for the public IP hostname."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of CIDR ranges allowed to SSH into the bastion host."
}

variable "bastion_ssh_public_key" {
  type        = string
  description = "SSH public key content for the bastion host."
}

variable "enable_bastion" {
  type        = bool
  default     = true
  description = "Set to false to skip bastion host provisioning."
}

variable "bastion_vm_size" {
  type        = string
  description = "VM size for the bastion host."
}

variable "app_image" {
  type        = string
  description = "Container image for the application."
}

variable "app_replica_count" {
  type        = number
  default     = 2
  description = "Number of replicas for the application Deployment."
}

variable "docker_username" {
  type        = string
  description = "Docker Hub username."
}

variable "docker_password" {
  type        = string
  sensitive   = true
  description = "Docker Hub password or PAT."
}
