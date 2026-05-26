#!/usr/bin/env bash
# Expose all three frontend environments and the ArgoCD UI locally.
# Re-runnable: it first drops any forwards a previous run left behind.
#
#   ./scripts/port-forward.sh
set -euo pipefail

# Escape a potentially deleted cwd so child processes (kubectl, pkill, etc.)
# don't print "shell-init: error retrieving current directory" each call.
cd "$HOME" 2>/dev/null || cd /

DEV_PORT="${DEV_PORT:-8080}"
TEST_PORT="${TEST_PORT:-8082}"
PROD_PORT="${PROD_PORT:-8083}"
ARGO_PORT="${ARGO_PORT:-8081}"

pkill -f "kubectl port-forward svc/frontend" 2>/dev/null || true
pkill -f "kubectl port-forward svc/argo-cd-argocd-server" 2>/dev/null || true
sleep 1

# Kill every backgrounded port-forward when this script is stopped (Ctrl-C).
trap 'kill 0' EXIT

kubectl port-forward svc/frontend -n dev  "${DEV_PORT}:8080"  >/dev/null &
kubectl port-forward svc/frontend -n test "${TEST_PORT}:8080" >/dev/null &
kubectl port-forward svc/frontend -n prod "${PROD_PORT}:8080" >/dev/null &
kubectl port-forward svc/argo-cd-argocd-server -n argocd "${ARGO_PORT}:443" >/dev/null &

ARGO_PW="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"

cat <<EOF

  Frontend (dev)   http://localhost:${DEV_PORT}
  Frontend (test)  http://localhost:${TEST_PORT}
  Frontend (prod)  http://localhost:${PROD_PORT}
  ArgoCD           https://localhost:${ARGO_PORT}   (admin / ${ARGO_PW:-see argocd-initial-admin-secret})

  Ctrl-C to stop.
EOF

wait
