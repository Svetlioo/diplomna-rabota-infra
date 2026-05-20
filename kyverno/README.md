# kyverno

Installs Kyverno admission controller into the AKS cluster via Helm.

Policies themselves live in the gitops repo under `policies/` and are deployed by ArgoCD — this module only installs the engine.

## Apply

```bash
terraform init
terraform apply
```

Reads AKS kubeconfig from `aks.tfstate` via `terraform_remote_state`.

## Verify

```bash
kubectl get pods -n kyverno
kubectl get crd | grep kyverno
```
