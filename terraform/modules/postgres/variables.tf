variable "location" {
  type        = string
  description = "Azure region where the PostgreSQL server will be provisioned."
}

variable "environment" {
  type        = string
  description = "Environment label used in resource naming."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group to deploy into."
}

variable "vnet_id" {
  type        = string
  description = "ID of the Virtual Network for the private DNS zone link."
}

variable "postgres_subnet_id" {
  type        = string
  description = "ID of the delegated subnet for PostgreSQL Flexible Server VNet integration."
}

variable "sku_name" {
  type        = string
  default     = "B_Standard_B1ms"
  description = "SKU name for the PostgreSQL Flexible Server. Defaults to B_Standard_B1ms for dev cost savings."
}

variable "admin_username" {
  type        = string
  default     = "psqladmin"
  description = "Administrator login username for the PostgreSQL server."
}

# Requirement 4.3 — accept password as sensitive variable; never hard-coded
variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for the PostgreSQL server. Must meet Azure complexity requirements."
}

variable "database_name" {
  type        = string
  default     = "appdb"
  description = "Name of the application database to create on the PostgreSQL server."
}
