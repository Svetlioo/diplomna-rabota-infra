resource "kubernetes_namespace_v1" "falco" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "falco" {
  name       = "falco"
  namespace  = kubernetes_namespace_v1.falco.metadata[0].name
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  version    = var.chart_version

  values = [file("${path.module}/values.yaml")]
}
