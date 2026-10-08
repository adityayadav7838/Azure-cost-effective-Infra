variable "location" {
  type        = string
  description = "Azure region where networking resources will be provisioned."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
}

variable "vnet_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Address space for the Virtual Network."
}

variable "aks_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR block for the AKS node subnet."
}

variable "postgres_subnet_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR block for the PostgreSQL Flexible Server subnet."
}

variable "bastion_subnet_cidr" {
  type        = string
  default     = "10.0.3.0/24"
  description = "CIDR block for the bastion host subnet."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR ranges permitted to SSH into the bastion host."
}
