# diplomna-rabota-infra

Terraform инфраструктура за дипломната ([diplomna-rabota](https://github.com/Svetlioo/diplomna-rabota)).
Описва декларативно Azure ресурсите: споделена основа, AKS клъстер, база данни и
контролерите в клъстера (ArgoCD, Kyverno).

## Модули

| Модул | Предназначение |
|---|---|
| [`shared/`](./shared) | Resource group и storage account за remote state на останалите модули. Собственият му state остава локален. |
| [`aks/`](./aks) | AKS клъстер с един node pool (`Standard_B2s_v2`), SystemAssigned identity. |
| [`data/`](./data) | PostgreSQL Flexible Server, по една база на среда (`bank_dev/test/prod`) и Kubernetes secret `bank-service-db` (DB достъп и `JWT_SECRET`) във всеки namespace. |
| [`argocd/`](./argocd) | Инсталира ArgoCD чрез Helm (GitOps доставка от `diplomna-rabota-gitops`). |
| [`kyverno/`](./kyverno) | Инсталира Kyverno чрез Helm (контрол на допускането). |
| [`scripts/`](./scripts) | `aks-start.sh` / `aks-stop.sh` за пускане и спиране на клъстера (пестене на кредити); `port-forward.sh` за локален достъп до трите frontend среди и ArgoCD UI. |

## Предпоставки

- Инсталирани `terraform`, `kubectl`, `az`, `helm`.
- Логнат Azure акаунт:
  ```bash
  az login
  az account set --subscription <SUBSCRIPTION_ID>
  ```
- Регистриран PostgreSQL provider (еднократно за абонамента):
  ```bash
  az provider register --namespace Microsoft.DBforPostgreSQL --wait
  ```
- Gitleaks hook за тайни (еднократно след клониране): `pre-commit install`
- `terraform.tfvars` файлове (gitignored; копирай от `*.example` и попълни):
  - `shared/terraform.tfvars`: `subscription_id`, `state_storage_account_name` (глобално уникално)
  - `aks/terraform.tfvars`: `subscription_id`
  - `data/terraform.tfvars`: `subscription_id`, `server_name` (глобално уникално)

## Пускане от нула

Редът е важен: namespace-ите `dev/test/prod` се създават от ArgoCD bootstrap-а, а
secret-ът от модула `data`. Затова `data` се прилага СЛЕД bootstrap, иначе гърми
с "namespace not found".

**1. shared** (локален state, създава storage account-а за останалите):
```bash
cd shared && terraform init && terraform apply
```

**2. aks** (самият клъстер, 5-7 мин):
```bash
cd ../aks && terraform init && terraform apply
```

**3. kubeconfig**:
```bash
az aks get-credentials --resource-group rg-diploma-aks --name aks-diploma --overwrite-existing
```

**4. argocd**:
```bash
cd ../argocd && terraform init && terraform apply
```

**5. kyverno** (преди bootstrap, защото политиките искат Kyverno CRD-тата):
```bash
cd ../kyverno && terraform init && terraform apply
```

**6. bootstrap** от gitops хранилището (root app-of-apps + AppProject; ArgoCD
създава namespace-ите и започва да внедрява):
```bash
cd ../../diplomna-rabota-gitops
kubectl apply -f bootstrap/
kubectl get ns dev test prod
```
Pod-овете ще са в `CreateContainerConfigError` до следващата стъпка (липсва DB
secret). Нормално е.

**7. data** (база, бази по среда, secrets в трите namespace-а):
```bash
cd ../diplomna-rabota-infra/data && terraform init && terraform apply
```
DB паролата и `JWT_SECRET` се генерират наново при всяко пресъздаване; старите
JWT токени стават невалидни.

**8. рестарт на pod-овете** (по-бързо от изчакване):
```bash
kubectl rollout restart deployment -n dev
kubectl rollout restart deployment -n test
kubectl rollout restart deployment -n prod
```

**9. проверка**:
```bash
kubectl get applications -n argocd
kubectl get pods -A
```

## Локален достъп

`port-forward.sh` вдига наведнъж трите frontend среди и ArgoCD UI и показва
адресите и admin паролата:
```bash
./scripts/port-forward.sh
# dev.localhost:8080, test.localhost:8082, prod.localhost:8083, ArgoCD https://localhost:8081
```
Отделните `*.localhost` адреси дават на всяка среда собствени cookies, така че
може да си логнат в трите едновременно.

Само ArgoCD UI на ръка:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
# https://localhost:8080, потребител admin
```

## Спиране и пускане

Не е нужно разрушаване; спира се само compute-ът, данните остават:
```bash
./scripts/aks-stop.sh
./scripts/aks-start.sh
```
AKS control plane е безплатен; плаща се node VM-ът и PostgreSQL compute.

## Destroy

Обратен ред, докато клъстерът е още жив:
```
kyverno → argocd → data → aks → shared
```
Във всеки модул: `terraform destroy`.

## Настройка на хранилището (еднократно)

- Branch ruleset на `main`: изисква pull request и преминали проверки (Gitleaks,
  Trivy config); забранен директен push.

## Свързани хранилища

- **`diplomna-rabota`**: изходен код на услугите и CI/CD.
- **`diplomna-rabota-gitops`**: желано състояние, което ArgoCD синхронизира.

## Лиценз

[Apache License 2.0](LICENSE)
