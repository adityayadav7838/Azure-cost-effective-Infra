# Staging environment root module

module "networking" {
  source = "../../modules/networking"

  location          = var.location
  environment       = var.environment
  vnet_cidr         = var.vnet_cidr
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

module "bastion" {
  source = "../../modules/bastion"
  count  = var.enable_bastion ? 1 : 0

  location            = var.location
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.bastion_subnet_id
  ssh_public_key      = var.bastion_ssh_public_key
  vm_size             = var.bastion_vm_size
  enable_bastion      = var.enable_bastion
}

module "kubernetes" {
  source = "../../modules/kubernetes"

  location            = var.location
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  subnet_id           = module.networking.aks_subnet_id
  node_vm_size        = var.aks_node_vm_size
}

module "postgres" {
  source = "../../modules/postgres"

  location            = var.location
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  vnet_id             = module.networking.vnet_id
  postgres_subnet_id  = module.networking.postgres_subnet_id
  sku_name            = var.postgres_sku
  admin_username      = var.postgres_admin_username
  admin_password      = var.postgres_admin_password
}

module "traefik" {
  source = "../../modules/traefik"

  location            = var.location
  environment         = var.environment
  resource_group_name = module.networking.resource_group_name
  dns_label           = var.dns_label
  aks_principal_id    = module.kubernetes.aks_principal_id
  depends_on = [module.kubernetes]
}

module "app" {
  source = "../../modules/app"

  postgres_fqdn           = module.postgres.postgres_fqdn
  postgres_database_name  = module.postgres.postgres_database_name
  postgres_admin_username = module.postgres.postgres_admin_username
  postgres_admin_password = var.postgres_admin_password
  application_hostname    = module.traefik.application_hostname
  app_image               = var.app_image
  replica_count           = var.app_replica_count
  docker_username         = var.docker_username
  docker_password         = var.docker_password

  depends_on = [module.traefik]
}
