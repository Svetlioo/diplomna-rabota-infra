#!/usr/bin/env bash
# Expose one frontend environment and the ArgoCD UI locally via kubectl port-forward.
# Re-runnable: it first drops any forwards a previous run left behind.
#
#   ./scripts/port-forward.sh                  # dev (default)
#   NS=test ./scripts/port-forward.sh          # test
#   NS=prod ./scripts/port-forward.sh          # prod
#
# Override ports if needed: FE_PORT=9000 ./scripts/port-forward.sh
set -euo pipefail

cd "$HOME" 2>/dev/null || cd /

NS="${NS:-dev}"
FE_PORT="${FE_PORT:-8080}"
ARGO_PORT="${ARGO_PORT:-8081}"

pkill -f "kubectl port-forward svc/frontend" 2>/dev/null || true
pkill -f "kubectl port-forward svc/argo-cd-argocd-server" 2>/dev/null || true
sleep 1

trap 'kill 0' EXIT

kubectl port-forward "svc/frontend" -n "${NS}" "${FE_PORT}:8080" >/dev/null &
kubectl port-forward svc/argo-cd-argocd-server -n argocd "${ARGO_PORT}:443" >/dev/null &

ARGO_PW="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

cat <<EOF

  Frontend (${NS})   http://localhost:${FE_PORT}
  ArgoCD             https://localhost:${ARGO_PORT}   (admin / ${ARGO_PW:-see argocd-initial-admin-secret})

  Switch env (Ctrl-C first, then clear localhost cookies in DevTools):

      NS=test ${SELF}
      NS=prod ${SELF}
      NS=dev  ${SELF}

  Ctrl-C to stop.
EOF

wait
