#!/usr/bin/env bash
# Expose all three frontend environments and the ArgoCD UI locally.
# Adds /etc/hosts aliases (bank-dev/test/prod) so each env is a separate cookie
# jar, then removes them again when the script stops.
#
#   ./scripts/port-forward.sh
#
# Prompts once for sudo to edit /etc/hosts.
set -euo pipefail

cd "$HOME" 2>/dev/null || cd /

DEV_PORT="${DEV_PORT:-8080}"
TEST_PORT="${TEST_PORT:-8082}"
PROD_PORT="${PROD_PORT:-8083}"
ARGO_PORT="${ARGO_PORT:-8081}"

HOSTS_MARKER="# diploma-port-forward"
HOSTS_LINE="127.0.0.1 bank-dev bank-test bank-prod ${HOSTS_MARKER}"

cleanup() {
  # Drop the hosts entry we added (also runs if grep/sed below was a no-op).
  sudo sed -i.bak "/${HOSTS_MARKER}/d" /etc/hosts 2>/dev/null && sudo rm -f /etc/hosts.bak
  kill 0 2>/dev/null || true
}
trap cleanup EXIT

# Idempotent insert (re-runs of the script don't pile up duplicate lines).
if ! grep -qF "${HOSTS_MARKER}" /etc/hosts; then
  echo "Adding bank-dev/test/prod to /etc/hosts (sudo)..."
  echo "${HOSTS_LINE}" | sudo tee -a /etc/hosts >/dev/null
fi

pkill -f "kubectl port-forward svc/frontend" 2>/dev/null || true
pkill -f "kubectl port-forward svc/argo-cd-argocd-server" 2>/dev/null || true
sleep 1

kubectl port-forward svc/frontend -n dev  "${DEV_PORT}:8080"  >/dev/null &
kubectl port-forward svc/frontend -n test "${TEST_PORT}:8080" >/dev/null &
kubectl port-forward svc/frontend -n prod "${PROD_PORT}:8080" >/dev/null &
kubectl port-forward svc/argo-cd-argocd-server -n argocd "${ARGO_PORT}:443" >/dev/null &

ARGO_PW="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"

cat <<EOF

  Frontend (dev)   http://bank-dev:${DEV_PORT}
  Frontend (test)  http://bank-test:${TEST_PORT}
  Frontend (prod)  http://bank-prod:${PROD_PORT}
  ArgoCD           https://localhost:${ARGO_PORT}   (admin / ${ARGO_PW:-see argocd-initial-admin-secret})

  Each hostname is a separate cookie jar; /etc/hosts entries are removed on Ctrl-C.
EOF

wait
