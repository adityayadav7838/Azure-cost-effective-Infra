output "cloud_region" {
  value = var.location
}

output "resource_group" {
  value = module.networking.resource_group_name
}

output "kubernetes_cluster_name" {
  value = module.kubernetes.cluster_name
}

output "postgres_endpoint" {
  value = module.postgres.postgres_fqdn
}

output "postgres_database_name" {
  value = module.postgres.postgres_database_name
}

output "traefik_public_ip" {
  value = module.traefik.traefik_public_ip
}

output "application_hostname" {
  value = module.traefik.application_hostname
}

output "bastion_public_ip" {
  value = var.enable_bastion ? module.bastion[0].bastion_public_ip : null
}

output "kube_config" {
  value     = module.kubernetes.kube_config
  sensitive = true
}
