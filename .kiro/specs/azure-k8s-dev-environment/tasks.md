# Implementation Plan

- [x] 1. Scaffold Terraform project structure and provider configuration
  - Create `terraform/versions.tf` with required providers: `azurerm`, `kubernetes`, `helm`, `time`
  - Create `terraform/providers.tf` configuring `azurerm` (features block), `kubernetes` and `helm` providers using AKS cluster outputs
  - Create `terraform/variables.tf` declaring all root input variables with types, defaults, and descriptions
  - Create `terraform/outputs.tf` with placeholder outputs (filled in as modules are built)
  - Create `terraform/terraform.tfvars.example` documenting all variables with example values and no secrets
  - _Requirements: 8.1, 8.2, 8.6_

- [x] 2. Implement networking module
  - [x] 2.1 Create `modules/networking/main.tf` provisioning the Azure Resource Group, VNet, and three subnets (aks, postgres, bastion) with the CIDR layout from the design
    - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - [x] 2.2 Add NSG resources and subnet associations in `modules/networking/main.tf` with rules: SSH-only on bastion, VNet-internal on AKS, port-5432-from-AKS-subnet on postgres
    - _Requirements: 1.5, 2.3, 4.6_
  - [x] 2.3 Create `modules/networking/variables.tf` and `modules/networking/outputs.tf` exposing `vnet_id`, `aks_subnet_id`, `postgres_subnet_id`, `bastion_subnet_id`, `resource_group_name`, `aks_subnet_cidr`
    - _Requirements: 1.1–1.5_

- [x] 3. Implement bastion module
  - [x] 3.1 Create `modules/bastion/main.tf` provisioning a Standard_B1s Ubuntu 22.04 VM with a static public IP and SSH public key authentication, guarded by `var.enable_bastion`
    - _Requirements: 2.1, 2.2, 2.4, 2.6_
  - [x] 3.2 Create `modules/bastion/variables.tf` and `modules/bastion/outputs.tf` exposing `bastion_public_ip`
    - _Requirements: 2.5_

- [x] 4. Implement AKS module
  - [x] 4.1 Create `modules/kubernetes/main.tf` provisioning an AKS cluster with a single-node system pool, SystemAssigned Managed Identity, Azure CNI network plugin, and Standard load balancer SKU
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 4.2 Create `modules/kubernetes/variables.tf` and `modules/kubernetes/outputs.tf` exposing `cluster_name`, `kube_config` (sensitive), `cluster_id`
    - _Requirements: 3.5, 3.6_

- [x] 5. Implement PostgreSQL module
  - [x] 5.1 Create `modules/postgres/main.tf` provisioning the PostgreSQL Flexible Server with VNet integration (delegated subnet), private DNS zone, and DNS zone VNet link; disable public network access
    - _Requirements: 4.1, 4.2, 4.6_
  - [x] 5.2 Add an `azurerm_postgresql_flexible_server_database` resource for the application database; accept admin password via sensitive variable
    - _Requirements: 4.3_
  - [x] 5.3 Create `modules/postgres/variables.tf` and `modules/postgres/outputs.tf` exposing `postgres_fqdn`, `postgres_database_name`, `postgres_admin_username`
    - _Requirements: 4.4, 4.5_

- [x] 6. Implement Traefik module
  - [x] 6.1 Create `modules/traefik/main.tf` with an `azurerm_public_ip` resource (Static, Standard SKU) and a `helm_release` for the official `traefik/traefik` chart; pass Helm values to configure LoadBalancer service type, ports 80/443, and the Azure DNS label annotation pointing to the public IP
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 6.1, 6.2_
  - [x] 6.2 Create `modules/traefik/variables.tf` and `modules/traefik/outputs.tf` exposing `traefik_public_ip` and `application_hostname`
    - _Requirements: 5.5, 6.3_

- [x] 7. Implement sample application module
  - [x] 7.1 Write the sample application source code as a minimal Python (FastAPI) or Go HTTP server implementing `GET /` and `GET /health` with PostgreSQL connectivity check; add a `Dockerfile`
    - _Requirements: 7.2, 7.3, 7.4, 7.5_
  - [x] 7.2 Create `modules/app/main.tf` provisioning a Kubernetes Secret containing the PostgreSQL connection string, a Deployment (1 replica) referencing the secret as an env var, a ClusterIP Service, and a Traefik Ingress resource routing the DNS hostname
    - _Requirements: 7.1, 7.6, 7.7_
  - [x] 7.3 Create `modules/app/variables.tf` and `modules/app/outputs.tf`
    - _Requirements: 7.1_

- [x] 8. Wire root module and complete outputs
  - Create `terraform/main.tf` calling all modules in dependency order (networking → bastion, kubernetes, postgres → traefik → app) with correct input wiring
  - Populate `terraform/outputs.tf` with all required root outputs: `cloud_region`, `resource_group`, `kubernetes_cluster_name`, `postgres_endpoint`, `postgres_database_name`, `traefik_public_ip`, `application_hostname`, `bastion_public_ip`, `kube_config` (sensitive)
  - _Requirements: 8.1, 8.7, 8.8_

- [x] 9. Write end-to-end validation script
  - Create a `scripts/validate.sh` that runs `curl` against `/` and `/health` on the `application_hostname` output and exits non-zero on unexpected responses
  - _Requirements: 8.3, 8.4, 8.5_
