#!/usr/bin/env bash
set -euo pipefail

AKS_RG="rg-diploma-aks"
AKS_CLUSTER="aks-diploma"

DATA_RG="rg-diploma-data"
PG_SERVER="psql-diplomarabota-26"

echo "Starting PostgreSQL server $PG_SERVER..."
az postgres flexible-server start --resource-group "$DATA_RG" --name "$PG_SERVER"

echo "Starting AKS cluster $AKS_CLUSTER..."
az aks start --resource-group "$AKS_RG" --name "$AKS_CLUSTER"

echo "Refreshing kubeconfig..."
az aks get-credentials --resource-group "$AKS_RG" --name "$AKS_CLUSTER" --overwrite-existing

echo "Done. Test:"
echo "  kubectl get nodes"
