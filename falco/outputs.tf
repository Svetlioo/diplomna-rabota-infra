output "namespace" {
  description = "Namespace where Falco is installed."
  value       = kubernetes_namespace_v1.falco.metadata[0].name
}

output "chart_version" {
  description = "Installed Falco Helm chart version."
  value       = helm_release.falco.version
}
