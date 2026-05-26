#!/usr/bin/env bash
# Expose all three frontend environments and the ArgoCD UI locally.
# Re-runnable: drops any forwards a previous run left behind.
#
#   ./scripts/port-forward.sh
#
# Uses *.localhost hostnames so each env has its own cookie jar without
# touching /etc/hosts. Browsers auto-resolve *.localhost to 127.0.0.1 and
# treat it as a secure context, so Secure cookies still work over HTTP.
set -euo pipefail

cd "$HOME" 2>/dev/null || cd /

DEV_PORT="${DEV_PORT:-8080}"
TEST_PORT="${TEST_PORT:-8082}"
PROD_PORT="${PROD_PORT:-8083}"
ARGO_PORT="${ARGO_PORT:-8081}"

pkill -f "kubectl port-forward svc/frontend" 2>/dev/null || true
pkill -f "kubectl port-forward svc/argo-cd-argocd-server" 2>/dev/null || true
sleep 1

trap 'kill 0' EXIT

kubectl port-forward svc/frontend -n dev  "${DEV_PORT}:8080"  >/dev/null &
kubectl port-forward svc/frontend -n test "${TEST_PORT}:8080" >/dev/null &
kubectl port-forward svc/frontend -n prod "${PROD_PORT}:8080" >/dev/null &
kubectl port-forward svc/argo-cd-argocd-server -n argocd "${ARGO_PORT}:443" >/dev/null &

ARGO_PW="$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)"

cat <<EOF

  Frontend (dev)   http://dev.localhost:${DEV_PORT}
  Frontend (test)  http://test.localhost:${TEST_PORT}
  Frontend (prod)  http://prod.localhost:${PROD_PORT}
  ArgoCD           https://localhost:${ARGO_PORT}   (admin / ${ARGO_PW:-see argocd-initial-admin-secret})

  Open the three URLs in normal tabs of any browser - each is its own cookie
  jar, so logins in dev/test/prod do not collide.

  Ctrl-C to stop.
EOF

wait
