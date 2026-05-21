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

## Ред на прилагане

1. **`shared/`** — първо, с локален state, за да създаде remote backend-а.
2. **`aks/`** — ползва remote backend-а; създава клъстера.
3. **`data/`**, **`argocd/`**, **`kyverno/`** — след клъстера (нужен е kube достъп).

Всеки модул има свой `README.md` с inputs, outputs и инструкции за apply.

> Бележка: преименуване на DB име в `data/` (напр. `account_*` → `bank_*`) форсира
> replace на базите/secret-ите — допустима загуба на данни в dev (Flyway пресъздава схемата при старт).

## Свързани репозитории

- **`diplomna-rabota`** — сорс на сервизите + CI/CD.
- **`diplomna-rabota-gitops`** — desired state, който ArgoCD (инсталиран оттук) реконсилира.

## Лиценз

[Apache License 2.0](LICENSE)
