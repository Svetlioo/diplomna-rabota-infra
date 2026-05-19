#!/usr/bin/env bash
set -euo pipefail

AKS_RG="rg-diploma-aks"
AKS_CLUSTER="aks-diploma"

DATA_RG="rg-diploma-data"
PG_SERVER="psql-diplomarabota-26"

echo "Stopping AKS cluster $AKS_CLUSTER..."
az aks stop --resource-group "$AKS_RG" --name "$AKS_CLUSTER" --no-wait

echo "Stopping PostgreSQL server $PG_SERVER..."
az postgres flexible-server stop --resource-group "$DATA_RG" --name "$PG_SERVER" --no-wait

echo "Stop initiated for both. Verify:"
echo "  az aks show -g $AKS_RG -n $AKS_CLUSTER --query powerState.code -o tsv"
echo "  az postgres flexible-server show -g $DATA_RG -n $PG_SERVER --query state -o tsv"
