output "namespace" {
  description = "Namespace where ArgoCD is installed."
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "chart_version" {
  description = "Installed argo-cd Helm chart version."
  value       = helm_release.argocd.version
}
