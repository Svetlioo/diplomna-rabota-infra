# diplomna-rabota-infra

Terraform infrastructure for the diploma project ([diplomna-rabota](https://github.com/Svetlioo/diplomna-rabota)).

Provisions Azure resources hosting the containerized banking demo: shared foundation (resource group + remote state storage) and the AKS cluster.

## Modules

| Module | Purpose |
|---|---|
| [`shared/`](./shared) | Resource group + Storage Account holding Terraform remote state for all other modules. Bootstrap only — its own state stays local. |
| [`aks/`](./aks) | Azure Kubernetes Service cluster. State stored remotely in the storage account created by `shared/`. |

## Order of apply

1. `shared/` — first, with local state, to create the remote state backend.
2. `aks/` — uses the remote backend created above.

Each module has its own `README.md` with inputs, outputs, and apply instructions.
