#!/usr/bin/env bash
# Expose the dev frontend and the ArgoCD UI locally via kubectl port-forward.
# Re-runnable: it first drops any forwards a previous run left behind.
#
#   ./scripts/port-forward.sh
#
# Override ports/namespace if needed: FE_PORT=9000 NS=test ./scripts/port-forward.sh
set -euo pipefail

# Escape a potentially deleted cwd so child processes (kubectl, pkill, etc.)
# don't print "shell-init: error retrieving current directory" each call.
cd "$HOME" 2>/dev/null || cd /

NS="${NS:-dev}"
FE_PORT="${FE_PORT:-8080}"
ARGO_PORT="${ARGO_PORT:-8081}"

pkill -f "port-forward svc/frontend -n ${NS}" 2>/dev/null || true
pkill -f "port-forward svc/argo-cd-argocd-server" 2>/dev/null || true
sleep 1

# Kill both port-forwards when this script is stopped (Ctrl-C).
trap 'kill 0' EXIT

kubectl port-forward "svc/frontend" -n "${NS}" "${FE_PORT}:8080" >/dev/null &
kubectl port-forward svc/argo-cd-argocd-server -n argocd "${ARGO_PORT}:443" >/dev/null &

ARGO_PW="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"

cat <<EOF

  Frontend   http://localhost:${FE_PORT}
  ArgoCD     https://localhost:${ARGO_PORT}   (admin / ${ARGO_PW:-see argocd-initial-admin-secret})

  Ctrl-C to stop.
EOF

wait
