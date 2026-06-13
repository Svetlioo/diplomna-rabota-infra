# diplomna-rabota-infra

Terraform инфраструктура за дипломната ([diplomna-rabota](https://github.com/Svetlioo/diplomna-rabota)).
Описва декларативно Azure ресурсите за проекта: споделена основа, AKS клъстер,
база данни и контролерите в клъстера (ArgoCD, Kyverno).

## Структура

```
.
├── shared/    Resource group и storage account за remote state
├── aks/       AKS клъстер с един node pool
├── data/      PostgreSQL Flexible Server и secret за всяка среда
├── argocd/    Инсталация на ArgoCD (Helm)
└── kyverno/   Инсталация на Kyverno (Helm)
```

## Модули

| Модул | Предназначение |
|---|---|
| [`shared/`](./shared) | Resource group и storage account за remote state на останалите модули. Собственото му състояние се пази локално. |
| [`aks/`](./aks) | AKS клъстер с един node pool (`Standard_B2s_v2`). |
| [`data/`](./data) | PostgreSQL Flexible Server с отделна база за всяка среда (`bank_dev/test/prod`) и Kubernetes secret `bank-service-db` за достъп до базата и `JWT_SECRET` във всеки namespace. |
| [`argocd/`](./argocd) | Инсталира ArgoCD чрез Helm за GitOps доставка от `diplomna-rabota-gitops`. |
| [`kyverno/`](./kyverno) | Инсталира Kyverno чрез Helm за контрол на допускането. |
| [`scripts/`](./scripts) | `aks-start.sh` и `aks-stop.sh` пускат и спират клъстера за пестене на кредити, а `port-forward.sh` дава локален достъп до трите frontend среди и ArgoCD UI. |

## Предпоставки

- Инсталирани `terraform`, `kubectl`, `az` и `helm`.
- Активна Azure сесия:
  ```bash
  az login
  az account set --subscription <SUBSCRIPTION_ID>
  ```
- Регистриран PostgreSQL provider (еднократно за абонамента):
  ```bash
  az provider register --namespace Microsoft.DBforPostgreSQL --wait
  ```
- Gitleaks hook за тайни се активира еднократно след клониране с `pre-commit install`.
- Файлове `terraform.tfvars` (локални, не се качват в git; копират се от `*.example`).
  Всеки модул иска `subscription_id`; `shared` иска и `state_storage_account_name`,
  а `data` иска и `server_name` (двете глобално уникални).

## Пускане от нула

Редът има значение. Трите namespace `dev`, `test` и `prod` се създават при
bootstrap на ArgoCD, а secret с достъпа до базата идва от модула `data`. Затова
`data` се прилага след bootstrap, иначе прилагането пропада с грешката
"namespace not found".

**1. shared** (локално състояние; създава storage account за останалите модули):
```bash
cd shared && terraform init && terraform apply
```

**2. aks** (самият клъстер):
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

**5. kyverno** (преди bootstrap, защото политиките зависят от CRD на Kyverno):
```bash
cd ../kyverno && terraform init && terraform apply
```

**6. bootstrap** от gitops хранилището (зарежда root app-of-apps и AppProject;
ArgoCD създава трите namespace и започва внедряването):
```bash
cd ../../diplomna-rabota-gitops
kubectl apply -f bootstrap/
kubectl get ns dev test prod
```

**7. data** (база, отделни бази по среда и secret в трите namespace):
```bash
cd ../diplomna-rabota-infra/data && terraform init && terraform apply
```
Паролата за базата и `JWT_SECRET` се генерират наново при всяко пресъздаване;
старите JWT токени стават невалидни.

**8. проверка**:
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

Достъп само до ArgoCD UI:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
# https://localhost:8080, потребител admin
```

## Спиране и пускане

Скриптовете спират и пускат клъстера, за да се ограничат разходите, без да се
трият ресурси; данните остават:
```bash
./scripts/aks-stop.sh
./scripts/aks-start.sh
```

## Destroy

Обратен ред, докато клъстерът е още жив:
```
kyverno → argocd → data → aks → shared
```
Във всеки модул се изпълнява `terraform destroy`.

## Настройка на хранилището (еднократно)

- Branch ruleset на `main` изисква pull request и преминали проверки (Gitleaks,
  Trivy config) и забранява директен push.

## Свързани хранилища

- **`diplomna-rabota`** съдържа изходния код на услугите и CI/CD.
- **`diplomna-rabota-gitops`** пази желаното състояние, което ArgoCD синхронизира.

## Лиценз

[Apache License 2.0](LICENSE)
