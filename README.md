# diplomna-rabota-infra

Terraform инфраструктура за дипломната ([diplomna-rabota](https://github.com/Svetlioo/diplomna-rabota)).
Осигурява Azure ресурсите, които хостват приложението: shared foundation, AKS клъстер,
бази данни и cluster controllers (ArgoCD, Kyverno).

## Модули

| Модул | Предназначение |
|---|---|
| [`shared/`](./shared) | Resource group + Storage Account за **remote state** на всички други модули. Само bootstrap — собственият му state остава локален. |
| [`aks/`](./aks) | Azure Kubernetes Service клъстер. State в storage-а от `shared/`. |
| [`data/`](./data) | PostgreSQL flexible server + по една база на среда (`bank_dev/test/prod`) и Kubernetes secret `bank-service-db` (DB креденшъли + `JWT_SECRET`) на среда. |
| [`argocd/`](./argocd) | Инсталира ArgoCD в клъстера (GitOps reconciler — pull-ва от `diplomna-rabota-gitops`). |
| [`kyverno/`](./kyverno) | Инсталира Kyverno (admission control — проверка на Cosign подписи). |
| [`scripts/`](./scripts) | `aks-start.sh` / `aks-stop.sh` — спиране/пускане на клъстера (пестене на кредити). |

## Предпоставки

- `terraform`, `kubectl`, `az` (Azure CLI), `helm` инсталирани локално.
- Логнат Azure акаунт с достъп до абонамента:
  ```bash
  az login
  az account set --subscription <SUBSCRIPTION_ID>
  ```
- Регистриран PostgreSQL resource provider (еднократно за абонамента):
  ```bash
  az provider register --namespace Microsoft.DBforPostgreSQL --wait
  ```
- `terraform.tfvars` файлове на диска (gitignored, НЕ са в git — копирай от `*.example` и попълни):
  - `shared/terraform.tfvars` — `subscription_id`, `state_storage_account_name` (3-24 малки букви/цифри, глобално уникално)
  - `aks/terraform.tfvars` — `subscription_id`
  - `data/terraform.tfvars` — `subscription_id`, `server_name` (глобално уникално)

## Пускане от нула (стъпка по стъпка)

> Зависимост, която диктува реда: под-овете на приложението искат **namespace** + **secret**.
> namespace-ите `dev/test/prod` се създават от ArgoCD bootstrap-а (`CreateNamespace=true` в gitops apps),
> а secret-ът `bank-service-db` се създава от модула `data`. Затова **`data` върви СЛЕД bootstrap**,
> не преди него — иначе `data` гърми с „namespace not found".

**1. shared** — локален state; създава storage account-а за remote backend на всички останали модули. Първи задължително.
```bash
cd shared && terraform init && terraform apply
```

**2. aks** — самият клъстер (~5-7 мин).
```bash
cd ../aks && terraform init && terraform apply
```

**3. kubeconfig** — взимане на достъп до новия клъстер.
```bash
az aks get-credentials --resource-group rg-diploma-aks --name aks-diploma --overwrite-existing
```

**4. argocd** — инсталира ArgoCD (GitOps reconciler).
```bash
cd ../argocd && terraform init && terraform apply
```

**5. kyverno** — инсталира Kyverno (admission control). Трябва преди bootstrap-а, защото `kyverno-policies` app-ът иска Kyverno CRD-тата.
```bash
cd ../kyverno && terraform init && terraform apply
```

**6. bootstrap** — от **gitops** repo-то (`diplomna-rabota-gitops`). Прилага root app-of-apps + AppProject. ArgoCD създава namespace-ите `dev/test/prod` и започва да деплойва bank-service/fraud-detection + Kyverno политиките.
```bash
cd ../../diplomna-rabota-gitops
kubectl apply -f bootstrap/
kubectl get ns dev test prod    # изчакай трите namespace-а да се появят
```
> Под-овете ще са в `CreateContainerConfigError` (липсва DB secret-ът) — нормално, ще се вдигнат сами щом `data` го създаде на следващата стъпка.

**7. data** — Postgres flexible server + по една база на среда (`bank_dev/test/prod`) + secret `bank-service-db` (DB креденшъли + `JWT_SECRET`) в трите namespace-а.
```bash
cd ../diplomna-rabota-infra/data && terraform init && terraform apply
```
> DB admin паролата и `JWT_SECRET` се **регенерират** (нови random стойности) — старите JWT токени стават невалидни, нужен е повторен login.

**8. вдигане на под-овете** — kubelet сам подхваща secret-а, но за по-бързо:
```bash
kubectl rollout restart deployment -n dev
kubectl rollout restart deployment -n test
kubectl rollout restart deployment -n prod
```

**9. проверка** — всичко да е Synced + Healthy:
```bash
kubectl get applications -n argocd
kubectl get pods -A
```

## Достъп до ArgoCD UI (по избор)

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
# отвори https://localhost:8080, потребител admin
```

## Спиране и пускане (пестене на кредити)

Не разрушавай за през нощта — спри compute-а (пази данните):
```bash
./scripts/aks-stop.sh    # спира node VM-а + Postgres compute
./scripts/aks-start.sh   # пуска ги обратно
```
AKS control plane-ът е безплатен; плаща се за node VM-а (`Standard_B2s_v2`) + Postgres (`B1ms`).

## Събаряне (destroy)

Обратен ред — модулите, зависещи от клъстера, се рушат ДОКАТО клъстерът е още жив:
```
kyverno → argocd → data → aks → shared
```
Във всеки модул: `terraform destroy`.

Известни капани:
- **ArgoCD namespace засяда в `Terminating`** (Application CR-ите имат finalizer, а helm е махнал контролера → deadlock). Изчисти finalizer-ите и пусни destroy отново:
  ```bash
  kubectl get applications,appprojects -n argocd -o name \
    | xargs -r -I{} kubectl patch {} -n argocd --type=merge -p '{"metadata":{"finalizers":null}}'
  ```
- **Зает storage account name** — `stdiplomarabotastate26` е глобално уникален; ако `apply` на `shared` гръмне с „name in use" след скорошен destroy, изчакай 1-2 мин или вдигни последната цифра в `terraform.tfvars` + всички `backend.tf`.

> Бележка: преименуване на DB име в `data/` (напр. `account_*` → `bank_*`) форсира
> replace на базите/secret-ите — допустима загуба на данни в dev (Flyway пресъздава схемата при старт).

## Свързани репозитории

- **`diplomna-rabota`** — сорс на сервизите + CI/CD.
- **`diplomna-rabota-gitops`** — desired state, който ArgoCD (инсталиран оттук) реконсилира.

## Лиценз

[Apache License 2.0](LICENSE)
