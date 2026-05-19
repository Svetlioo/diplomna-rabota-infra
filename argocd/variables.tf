variable "namespace" {
  description = "Kubernetes namespace for the ArgoCD installation."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "argo-cd Helm chart version (https://github.com/argoproj/argo-helm)."
  type        = string
  default     = "9.5.14"
}
