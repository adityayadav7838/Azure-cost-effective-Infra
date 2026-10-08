variable "location" {
  type        = string
  description = "Azure region where bastion resources will be provisioned."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group to deploy the bastion host into."
}

variable "subnet_id" {
  type        = string
  description = "ID of the bastion subnet."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key configured on the bastion host for key-based authentication."
}

variable "vm_size" {
  type        = string
  default     = "Standard_B1s"
  description = "VM size for the bastion host. Defaults to Standard_B1s for cost efficiency."
}

variable "enable_bastion" {
  type        = bool
  default     = true
  description = "When false, all bastion resources are skipped."
}
