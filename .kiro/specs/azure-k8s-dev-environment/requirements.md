# Requirements Document

## Introduction

This document defines requirements for a development Kubernetes environment on Azure using Terraform. The environment provides a complete, reproducible infrastructure stack including a managed Kubernetes cluster (AKS), managed PostgreSQL (Azure Database for PostgreSQL Flexible Server), Traefik ingress, DNS hostname resolution, a bastion host for secure access, and a sample application that validates the full stack. The environment is optimised for cost and developer learning, not production scale, but is structured to support a future path to production.

## Glossary

- **AKS**: Azure Kubernetes Service — Azure's managed Kubernetes offering
- **Traefik**: An open-source ingress controller and reverse proxy deployed via Helm
- **Flexible Server**: Azure Database for PostgreSQL – Flexible Server, Azure's managed PostgreSQL offering
- **VNet**: Azure Virtual Network — the private network that contains all resources
- **NSG**: Network Security Group — Azure firewall rules applied at subnet or NIC level
- **Bastion Host**: A small, hardened VM in the VNet used as a jump server to manage infrastructure
- **Terraform**: Infrastructure-as-Code tool used to provision and manage all resources
- **Helm**: Kubernetes package manager used to deploy Traefik and other cluster components
- **Ingress**: A Kubernetes resource that routes external HTTP/HTTPS traffic to services inside the cluster
- **Load Balancer**: Azure-provisioned public load balancer created when a Kubernetes Service of type LoadBalancer is deployed
- **FQDN**: Fully Qualified Domain Name — the DNS hostname used to reach the application
- **terraform.tfvars**: File containing environment-specific variable values, excluded from source control
- **Managed Identity**: Azure-native identity mechanism used to grant AKS permissions without storing credentials
- **Dev Node Size**: A VM size appropriate for development workloads (e.g. Standard_B2s)

---

## Requirements

### Requirement 1 — Networking Foundation

**User Story:** As a cloud engineer, I want a well-structured VNet with appropriate subnets, so that all resources are isolated correctly and the environment can scale toward production networking patterns.

#### Acceptance Criteria

1. THE Terraform configuration SHALL provision an Azure VNet with a configurable address space.
2. THE Terraform configuration SHALL create a dedicated subnet for AKS nodes within the VNet.
3. THE Terraform configuration SHALL create a dedicated subnet for the PostgreSQL Flexible Server within the VNet.
4. THE Terraform configuration SHALL create a dedicated subnet for the bastion host within the VNet.
5. THE Terraform configuration SHALL attach NSGs to each subnet, permitting only the minimum required traffic for each subnet's purpose.
6. WHEN the AKS subnet requires outbound internet access, THE networking module SHALL route traffic through an appropriate Azure-managed path without requiring a manually configured NAT gateway in the development tier.

---

### Requirement 2 — Bastion Host

**User Story:** As a cloud engineer, I want a small bastion host in the VNet, so that I can securely SSH into the environment to manage resources without using an expensive VPN.

#### Acceptance Criteria

1. THE Terraform configuration SHALL provision a Linux VM in the bastion subnet using a development-appropriate size (e.g. Standard_B1s).
2. THE bastion host SHALL be reachable via SSH on port 22 from a configurable set of allowed source IP addresses.
3. THE NSG attached to the bastion subnet SHALL deny all inbound traffic except SSH from the configured source IP ranges.
4. THE Terraform configuration SHALL accept an SSH public key as a variable and configure the bastion host to use key-based authentication.
5. THE Terraform configuration SHALL output the bastion host's public IP address.
6. WHERE the environment variable `enable_bastion` is set to false, THE Terraform configuration SHALL skip bastion host provisioning to support environments where it is not needed.

---

### Requirement 3 — AKS Cluster

**User Story:** As a cloud engineer, I want a managed AKS cluster provisioned by Terraform, so that I can deploy Kubernetes workloads without managing control-plane infrastructure.

#### Acceptance Criteria

1. THE Terraform configuration SHALL provision an AKS cluster with a single node pool containing exactly one worker node.
2. THE AKS node pool SHALL use a development-appropriate VM size configurable via a Terraform variable (default: Standard_B2s).
3. THE AKS cluster SHALL use a Managed Identity for authenticating to Azure services.
4. THE AKS cluster SHALL be deployed into the AKS subnet within the provisioned VNet.
5. THE Terraform configuration SHALL output the AKS cluster name and the kubeconfig required to connect to it.
6. WHEN the cluster is provisioned, THE Terraform configuration SHALL mark the kubeconfig output as sensitive to prevent it being printed unnecessarily.

---

### Requirement 4 — Managed PostgreSQL

**User Story:** As a cloud engineer, I want a managed PostgreSQL database provisioned by Terraform, so that the sample application can demonstrate real database connectivity without managing a self-hosted database.

#### Acceptance Criteria

1. THE Terraform configuration SHALL provision an Azure Database for PostgreSQL Flexible Server using a development-appropriate SKU (e.g. Standard_B1ms).
2. THE PostgreSQL server SHALL be deployed with private network access only, reachable from the AKS subnet but not exposed to the public internet.
3. THE Terraform configuration SHALL accept the PostgreSQL administrator password as a sensitive Terraform variable and SHALL NOT hard-code credentials anywhere in the codebase.
4. THE Terraform configuration SHALL output the PostgreSQL server FQDN and database name.
5. WHEN the PostgreSQL server is provisioned, THE Terraform configuration SHALL mark the administrator password output as sensitive.
6. THE Terraform configuration SHALL configure the PostgreSQL server firewall to permit connections from the AKS subnet CIDR and deny all other inbound connections.

---

### Requirement 5 — Traefik Ingress

**User Story:** As a cloud engineer, I want Traefik deployed into the AKS cluster via Helm and Terraform, so that all application routing is managed through a single ingress controller without manual installation steps.

#### Acceptance Criteria

1. THE Terraform configuration SHALL deploy Traefik into the AKS cluster using the official Traefik Helm chart via the Terraform Helm provider.
2. THE Traefik deployment SHALL create a Kubernetes Service of type LoadBalancer, causing Azure to provision a public Load Balancer.
3. WHEN the Traefik LoadBalancer service is created, THE Azure Load Balancer SHALL receive a stable public IP address.
4. THE Traefik configuration SHALL support HTTP (port 80) and HTTPS (port 443) ingress.
5. THE Terraform configuration SHALL output the Traefik public IP address.
6. THE Traefik deployment SHALL be configurable to support additional applications by creating standard Kubernetes Ingress resources.

---

### Requirement 6 — DNS Hostname

**User Story:** As a cloud engineer, I want the environment to expose a stable DNS hostname pointing to the Traefik Load Balancer, so that the application is reachable via a human-readable URL rather than a raw IP address.

#### Acceptance Criteria

1. THE Terraform configuration SHALL configure an Azure-provided DNS hostname in the format `<dns_label>.<region>.cloudapp.azure.com` using the DNS label feature of the Azure Public IP resource.
2. THE DNS hostname SHALL resolve to the Traefik Load Balancer public IP address.
3. THE Terraform configuration SHALL output the fully qualified DNS hostname.
4. WHEN a user sends an HTTP or HTTPS request to the DNS hostname, THE request SHALL reach the Traefik ingress controller.

---

### Requirement 7 — Sample Application

**User Story:** As a cloud engineer, I want a minimal sample application deployed to AKS and routable through Traefik, so that I can validate that the full infrastructure stack is functioning correctly.

#### Acceptance Criteria

1. THE Terraform configuration SHALL deploy a sample application as a Kubernetes Deployment with a configurable replica count (default: 1).
2. THE sample application SHALL respond to `GET /` with the body `Hello from Azure Kubernetes`.
3. THE sample application SHALL expose a `GET /health` endpoint returning a JSON body indicating application health and PostgreSQL connectivity status.
4. WHEN the PostgreSQL connection is healthy, THE `/health` endpoint SHALL return `{"application": "healthy", "database": "connected"}`.
5. IF the PostgreSQL connection fails, THEN THE `/health` endpoint SHALL return `{"application": "healthy", "database": "disconnected"}` with an HTTP 200 status, so the application remains reachable even if the database is temporarily unavailable.
6. THE sample application SHALL be exposed through a Kubernetes Service and routed via a Traefik Ingress resource using the configured DNS hostname.
7. THE sample application SHALL read the PostgreSQL connection string from a Kubernetes Secret, not from hardcoded values.

---

### Requirement 8 — Terraform Structure and Reproducibility

**User Story:** As a cloud engineer, I want the entire environment defined in parameterised, modular Terraform code, so that the environment can be created, updated, and destroyed repeatedly without manual steps.

#### Acceptance Criteria

1. THE Terraform codebase SHALL be organised into modules for networking, kubernetes, postgres, traefik, and bastion.
2. THE Terraform configuration SHALL use a `terraform.tfvars.example` file documenting all required and optional variables, with no secrets included.
3. WHEN running `terraform plan` from a clean checkout, THE plan SHALL complete without errors given valid variable values.
4. WHEN running `terraform apply`, THE complete environment SHALL be provisioned without requiring any manual cloud-console steps.
5. WHEN running `terraform destroy`, THE complete environment SHALL be removed cleanly with no orphaned resources.
6. THE Terraform configuration SHALL store no credentials, secrets, or sensitive values in source control.
7. THE Terraform configuration SHALL expose the minimum required outputs: cloud region, resource group, kubernetes cluster name, postgres endpoint, postgres database name, traefik public IP, and application hostname.
8. WHEN an output contains a sensitive value, THE Terraform configuration SHALL mark that output with `sensitive = true`.

---

### Requirement 9 — Cost and Sizing Constraints

**User Story:** As a cost-sensitive customer, I want the development environment to use the smallest practical Azure resources, so that the environment remains affordable while still providing a realistic learning experience.

#### Acceptance Criteria

1. THE AKS node pool SHALL use a VM size no larger than Standard_B2s by default, configurable via variable.
2. THE PostgreSQL Flexible Server SHALL use a SKU no larger than Standard_B1ms by default, configurable via variable.
3. THE bastion host SHALL use a VM size no larger than Standard_B1s by default, configurable via variable.
4. THE Terraform configuration SHALL use locally redundant storage (LRS) for any managed disks, rather than zone-redundant or geo-redundant options, in the development tier.
5. WHERE a high-availability option would increase cost without providing learning value, THE Terraform configuration SHALL default to single-instance or non-HA configuration for development.
