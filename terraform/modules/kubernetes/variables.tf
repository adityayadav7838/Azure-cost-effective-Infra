variable "location" {
  type        = string
  description = "Azure region where the AKS cluster will be provisioned."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group to deploy the AKS cluster into."
}

variable "subnet_id" {
  type        = string
  description = "ID of the AKS subnet within the VNet."
}

variable "node_vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "VM size for AKS node pool. Defaults to Standard_B2s for cost efficiency."
}
