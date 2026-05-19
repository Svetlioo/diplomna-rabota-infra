locals {
  aks = data.terraform_remote_state.aks.outputs
}

provider "kubernetes" {
  host                   = local.aks.host
  cluster_ca_certificate = base64decode(local.aks.cluster_ca_certificate)
  client_certificate     = base64decode(local.aks.client_certificate)
  client_key             = base64decode(local.aks.client_key)
}
