# falco

Installs the Falco runtime security engine as a DaemonSet into the AKS cluster via Helm.

Falco watches kernel syscalls (via the modern eBPF probe) and raises alerts on suspicious runtime behaviour. This module ships one custom rule — `Shell Spawned In Container` — covering attack #6 from the thesis.

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

## Trigger the alert (attack #6 demo)

The app images are hardened (Alpine + JRE, no `bash`/`nc`), so a `/dev/tcp`
reverse shell cannot run inside them — the attacker's first move is to spawn a
shell, which is what this rule detects on the real pod:

```bash
# simulate an attacker gaining an interactive shell in the banking pod
kubectl exec -it -n dev deploy/account-service -- sh

# watch Falco fire CRITICAL "Shell spawned in container"
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco -f | grep -i "Shell spawned"
```
