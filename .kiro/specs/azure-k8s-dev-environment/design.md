# Design Document — Azure Kubernetes Development Environment

## Overview

This document describes the technical design for a reproducible, cost-optimised Azure development environment provisioned entirely through Terraform. The stack covers networking (VNet/subnets/NSGs), a bastion host, AKS, Azure Database for PostgreSQL Flexible Server, Traefik ingress (deployed via Helm), DNS hostname resolution, and a minimal sample application that validates end-to-end connectivity.

The design prioritises:
- Low cost (B-series VMs, single nodes, no HA)
- Repeatability (`terraform apply` / `terraform destroy` with no manual steps)
- A clear upgrade path toward production (modular structure, parameterised sizing, private networking)

---

## Architecture

```
Internet
   |
   | HTTPS / HTTP
   v
Azure Public IP (DNS lazure cli login commandabel: <dns_label>.<region>.cloudapp.azure.com)
   |
   v
Azure Load Balancer  (provisioned automatically by AKS for the Traefik Service)
   |
   v
Traefik Ingress Controller  (Helm, running in AKS)
   |
   v
Kubernetes Ingress resource  (hostname-based routing)
   |
   v
Sample Application Service / Pods  (running in AKS)
   |
   v
Azure PostgreSQL Flexible Server  (private VNet integration, no public endpoint)


Management path:
Developer laptop  --SSH-->  Bastion Host (public IP)  --SSH/kubectl-->  AKS / resources
```

### VNet Layout

```
VNet: 10.0.0.0/16
  ├── subnet-aks        10.0.1.0/24   AKS node pool
  ├── subnet-postgres   10.0.2.0/24   PostgreSQL VNet integration
  ├── subnet-bastion    10.0.3.0/24   Bastion VM
```

---

## Terraform Module Structure

```
terraform/
├── main.tf                  # Root module — wires all child modules together
├── variables.tf             # All input variable declarations
├── outputs.tf               # All root outputs
├── versions.tf              # Required providers and version constraints
├── providers.tf             # Provider configuration (azurerm, kubernetes, helm)
├── terraform.tfvars.example # Documented example values, no secrets
│
└── modules/
    ├── networking/          # VNet, subnets, NSGs
    ├── bastion/             # Bastion VM, public IP, NSG rules
    ├── kubernetes/          # AKS cluster
    ├── postgres/            # PostgreSQL Flexible Server, private DNS zone
    ├── traefik/             # Helm release for Traefik, public IP
    └── app/                 # Kubernetes Deployment, Service, Ingress, Secret
```

Each module exposes typed `variables.tf` and `outputs.tf`. The root `main.tf` composes modules and passes outputs between them.

---

## Components and Interfaces

### 1. Networking Module (`modules/networking`)

Responsibilities:
- Create the Azure Resource Group
- Create the VNet
- Create three subnets (AKS, PostgreSQL, Bastion)
- Attach NSGs to each subnet

Key NSG rules:

| Subnet | Allow inbound | Deny |
|---|---|---|
| bastion | TCP 22 from `var.allowed_ssh_cidrs` | everything else |
| aks | traffic within VNet | direct public inbound (LB handles it) |
| postgres | TCP 5432 from AKS subnet CIDR | all other inbound |

Outputs: `vnet_id`, `aks_subnet_id`, `postgres_subnet_id`, `bastion_subnet_id`, `resource_group_name`, `aks_subnet_cidr`

### 2. Bastion Module (`modules/bastion`)

Responsibilities:
- Provision a Standard_B1s Linux VM (Ubuntu 22.04 LTS)
- Assign a static public IP
- Accept an SSH public key variable
- Conditionally skip provisioning when `enable_bastion = false`

Inputs: `resource_group_name`, `location`, `subnet_id`, `ssh_public_key`, `vm_size`, `enable_bastion`

Outputs: `bastion_public_ip`

### 3. Kubernetes Module (`modules/kubernetes`)

Responsibilities:
- Provision the AKS cluster
- Configure a single system node pool
- Assign a SystemAssigned Managed Identity
- Wire cluster to the AKS subnet

Key settings:
- `node_count = 1`
- `vm_size = var.aks_node_vm_size` (default `Standard_B2s`)
- `network_plugin = "azure"` (Azure CNI for proper VNet integration)
- `load_balancer_sku = "standard"` (required for public LB / Traefik)

Outputs: `cluster_name`, `kube_config` (sensitive), `cluster_id`

### 4. Postgres Module (`modules/postgres`)

Responsibilities:
- Provision a PostgreSQL Flexible Server with VNet integration (delegated subnet)
- Create a private DNS zone (`privatelink.postgres.database.azure.com`) and link it to the VNet
- Accept admin password as sensitive variable
- Create the application database

Key settings:
- `sku_name = var.postgres_sku` (default `B_Standard_B1ms`)
- `storage_mb = 32768` (32 GB, minimum)
- `version = "15"`
- Public network access disabled

Outputs: `postgres_fqdn`, `postgres_database_name`, `postgres_admin_username`

### 5. Traefik Module (`modules/traefik`)

Responsibilities:
- Use the Terraform `helm_release` resource to deploy the official `traefik/traefik` chart
- Configure Traefik to listen on ports 80 and 443
- Annotate the LoadBalancer service with the DNS label to obtain the Azure FQDN
- Wait for the LoadBalancer IP to be assigned and output it

Key Helm values passed via `set`:
```yaml
service.type: LoadBalancer
ports.web.port: 80
ports.websecure.port: 443
service.annotations:
  service.beta.kubernetes.io/azure-dns-label-name: <dns_label>
```

Outputs: `traefik_public_ip`, `application_hostname`

### 6. App Module (`modules/app`)

Responsibilities:
- Build a minimal Go or Python HTTP server image (or use a pre-built public image — see below)
- Deploy the application as a Kubernetes Deployment (1 replica)
- Create a Kubernetes Secret containing the PostgreSQL connection string
- Create a Kubernetes Service (ClusterIP)
- Create a Kubernetes Ingress resource routing the DNS hostname to the service

#### Sample Application

To avoid requiring a container registry in the dev environment, the sample application will be packaged as a small Docker image published to a public registry (Docker Hub or GHCR) as part of the spec. The image is a minimal Python (FastAPI) or Go HTTP server.

Endpoints:
- `GET /` → `200 Hello from Azure Kubernetes`
- `GET /health` → `200 {"application": "healthy", "database": "connected" | "disconnected"}`

The application reads `DATABASE_URL` from an environment variable sourced from the Kubernetes Secret.

Ingress resource:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: <application_hostname>
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: sample-app
                port:
                  number: 80
```

---

## Data Models

### Terraform Variable Interface (root)

| Variable | Type | Default | Sensitive | Description |
|---|---|---|---|---|
| `location` | string | `uksouth` | no | Azure region |
| `environment` | string | `dev` | no | Environment label used in naming |
| `vnet_cidr` | string | `10.0.0.0/16` | no | VNet address space |
| `aks_node_vm_size` | string | `Standard_B2s` | no | AKS node VM size |
| `postgres_sku` | string | `B_Standard_B1ms` | no | PostgreSQL SKU |
| `postgres_admin_password` | string | — | yes | PostgreSQL admin password |
| `postgres_admin_username` | string | `psqladmin` | no | PostgreSQL admin username |
| `dns_label` | string | — | no | Azure DNS label prefix |
| `allowed_ssh_cidrs` | list(string) | — | no | CIDRs allowed to SSH to bastion |
| `bastion_ssh_public_key` | string | — | no | SSH public key for bastion |
| `enable_bastion` | bool | `true` | no | Toggle bastion host provisioning |
| `bastion_vm_size` | string | `Standard_B1s` | no | Bastion VM size |

### Terraform Root Outputs

| Output | Sensitive | Description |
|---|---|---|
| `cloud_region` | no | Azure region |
| `resource_group` | no | Resource group name |
| `kubernetes_cluster_name` | no | AKS cluster name |
| `postgres_endpoint` | no | PostgreSQL FQDN |
| `postgres_database_name` | no | Database name |
| `traefik_public_ip` | no | Traefik LB public IP |
| `application_hostname` | no | Full DNS hostname |
| `bastion_public_ip` | no | Bastion host public IP |
| `kube_config` | yes | Kubeconfig for cluster access |

---

## Error Handling

### Terraform apply failures
- PostgreSQL VNet integration requires a delegated subnet. The subnet delegation is declared in the networking module so this dependency is met before the postgres module runs.
- The Helm provider depends on a valid kubeconfig. The kubernetes and helm providers are configured using the AKS cluster outputs, with explicit `depends_on` in the traefik and app modules.
- Traefik's LoadBalancer IP is assigned asynchronously by Azure. A `time_sleep` or `kubernetes_service` data source with `wait_for_load_balancer` can be used to stall until the IP is available before it is used in the DNS annotation.

### Application health failures
- The `/health` endpoint catches database connection errors and returns `disconnected` rather than crashing, so a misconfigured database does not prevent the endpoint from responding.

---

## Security Notes (Dev-appropriate, production upgrade path)

| Control | Dev implementation | Production upgrade |
|---|---|---|
| PostgreSQL access | Private VNet only, NSG restricts to AKS subnet | Private endpoint + Azure Private DNS |
| AKS API server | Public endpoint (default AKS) | Authorised IP ranges or private cluster |
| Bastion | SSH key auth, NSG allow-list | Azure Bastion PaaS or VPN Gateway |
| Secrets | Kubernetes Secrets (base64) | Azure Key Vault + CSI driver |
| TLS | HTTP only in dev (Traefik self-signed optional) | cert-manager + Let's Encrypt |

---

## Testing Strategy

Infrastructure validation is done by running the sample application after `terraform apply`:

1. `curl http://<application_hostname>/` — expect `Hello from Azure Kubernetes`
2. `curl http://<application_hostname>/health` — expect `{"application":"healthy","database":"connected"}`
3. `terraform plan` on a clean checkout — expect zero errors
4. `terraform destroy` — expect all resources removed

No automated test framework is added to keep the dev environment minimal. A production implementation would add Terratest or similar.
