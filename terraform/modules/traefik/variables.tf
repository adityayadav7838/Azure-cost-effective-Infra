variable "location" {
  type        = string
  description = "Azure region where the Traefik public IP will be provisioned."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group to deploy the public IP into."
}

variable "dns_label" {
  type        = string
  description = "DNS label prefix for the Azure public IP. Produces <dns_label>.<region>.cloudapp.azure.com."
}


variable "aks_principal_id" {
  type        = string
  description = "Principal ID of the AKS cluster to grant Network Contributor permissions"
}