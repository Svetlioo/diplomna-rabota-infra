output "namespace" {
  description = "Namespace where Kyverno is installed."
  value       = kubernetes_namespace_v1.kyverno.metadata[0].name
}

output "chart_version" {
  description = "Installed Kyverno Helm chart version."
  value       = helm_release.kyverno.version
}
