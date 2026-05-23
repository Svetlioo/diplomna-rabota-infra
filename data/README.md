# data

Provisions Azure Database for PostgreSQL Flexible Server (free tier B1ms — 750 hours/month free for 12 months on the Students plan) plus per-environment databases and Kubernetes secrets.

One shared server hosts three logical databases: `bank_dev`, `bank_test`, `bank_prod`. Each is exposed to its matching Kubernetes namespace via a `Secret` named `bank-service-db`.

> The `dev/test/prod` namespaces are NOT created here — they are created by the ArgoCD bootstrap
> (`CreateNamespace=true` in the gitops apps). Apply this module AFTER the bootstrap, otherwise the
> secrets fail with "namespace not found". See the repo root README for the full ordering.

## Resources

- `azurerm_resource_group` — `rg-diploma-data`
- `azurerm_postgresql_flexible_server` — version 17, Burstable B1ms, 32 GB
- `azurerm_postgresql_flexible_server_database` (×3) — one per environment (`bank_dev/test/prod`)
- `azurerm_postgresql_flexible_server_firewall_rule` — allows access from Azure-internal services (AKS outbound)
- `kubernetes_secret_v1` (×3) — `bank-service-db` with `SPRING_DATASOURCE_URL` / `USERNAME` / `PASSWORD` / `JWT_SECRET`
- `random_password` — admin password (32 chars) + per-env `JWT_SECRET` (64 chars), stored only in Terraform state and the Kubernetes secret

## State backend

Remote state in the shared storage account:
- Key: `data.tfstate`

AKS credentials are read from `aks.tfstate` via `terraform_remote_state`.

## Prerequisites

```bash
az provider register --namespace Microsoft.DBforPostgreSQL --wait
```

## Apply

```bash
cd data

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set subscription_id + server_name (globally unique, 3-63 lowercase chars)

terraform init
terraform plan
terraform apply
```

Provisioning takes 5–10 minutes.

## Inputs

| Name | Description | Default |
|---|---|---|
| `subscription_id` | Azure subscription ID | — |
| `location` | Azure region | `polandcentral` |
| `resource_group_name` | RG for data resources | `rg-diploma-data` |
| `server_name` | Globally unique server name | — |
| `postgres_version` | PostgreSQL major version | `17` |
| `admin_username` | Administrator login | `diploma_admin` |
| `environments` | Map of env → database name | `dev/test/prod` defaults |

## Outputs

| Name | Description |
|---|---|
| `server_fqdn` | Server hostname |
| `admin_username` | Administrator login (sensitive) |
| `admin_password` | Generated password (sensitive) |
| `databases` | Map of env → database name |
