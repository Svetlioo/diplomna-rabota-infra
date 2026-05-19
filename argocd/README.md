# argocd

Installs [Argo CD](https://argo-cd.readthedocs.io/) into the AKS cluster via the official [argo-helm](https://github.com/argoproj/argo-helm) chart.

This is the GitOps bootstrap layer — ArgoCD itself cannot install itself, so Terraform owns the initial deployment. After this module is applied, ArgoCD pulls all other workloads from the [diplomna-rabota-gitops](https://github.com/Svetlioo/diplomna-rabota-gitops) repository.

## Resources

- `kubernetes_namespace.argocd`
- `helm_release.argocd` — `argo-cd` chart from `https://argoproj.github.io/argo-helm`

## State backend

Remote state in the storage account created by `shared/`:
- Key: `argocd.tfstate`

AKS credentials are read from `aks.tfstate` via a `terraform_remote_state` data source.

## Apply

```bash
cd argocd

terraform init
terraform plan
terraform apply
```

## Access ArgoCD UI

ArgoCD is installed with ClusterIP services only (no Ingress yet). Port-forward to reach the UI:

```bash
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
```

Open `https://localhost:8080`. Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

## Inputs

| Name | Description | Default |
|---|---|---|
| `namespace` | Kubernetes namespace | `argocd` |
| `chart_version` | argo-cd Helm chart version | `9.5.14` |

## Outputs

| Name | Description |
|---|---|
| `namespace` | Namespace where ArgoCD is installed |
| `chart_version` | Installed chart version |
