variable "postgres_fqdn" {
  type        = string
  description = "FQDN of the PostgreSQL Flexible Server."
}

variable "postgres_database_name" {
  type        = string
  description = "Name of the application database on the PostgreSQL server."
}

variable "postgres_admin_username" {
  type        = string
  description = "Administrator username for the PostgreSQL server."
}

variable "postgres_admin_password" {
  type        = string
  sensitive   = true
  description = "Administrator password for the PostgreSQL server."
}

variable "application_hostname" {
  type        = string
  description = "DNS hostname used for the Traefik Ingress rule (e.g. <dns_label>.<region>.cloudapp.azure.com)."
}

variable "app_image" {
  type        = string
  description = "Container image for the sample application (e.g. ghcr.io/org/sample-app:latest)."
}

variable "replica_count" {
  type        = number
  default     = 1
  description = "Number of replicas for the sample application Deployment."
}

variable "docker_username" {
  type        = string
  description = "Docker Hub username for pulling the application image."
}

variable "docker_password" {
  type        = string
  sensitive   = true
  description = "Docker Hub password or Personal Access Token for pulling the application image."
}
