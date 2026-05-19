#!/usr/bin/env bash
set -euo pipefail

RG="rg-diploma-aks"
CLUSTER="aks-diploma"

echo "Starting AKS cluster $CLUSTER in $RG..."
az aks start --resource-group "$RG" --name "$CLUSTER"

echo "Cluster running. Refreshing kubeconfig..."
az aks get-credentials --resource-group "$RG" --name "$CLUSTER" --overwrite-existing

echo "Done. Test:"
echo "  kubectl get nodes"
