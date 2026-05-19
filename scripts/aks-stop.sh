#!/usr/bin/env bash
set -euo pipefail

RG="rg-diploma-aks"
CLUSTER="aks-diploma"

echo "Stopping AKS cluster $CLUSTER in $RG..."
az aks stop --resource-group "$RG" --name "$CLUSTER" --no-wait

echo "Stop initiated. Verify with:"
echo "  az aks show -g $RG -n $CLUSTER --query powerState.code -o tsv"
