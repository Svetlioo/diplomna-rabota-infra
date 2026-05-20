variable "namespace" {
  description = "Namespace to install Kyverno into."
  type        = string
  default     = "kyverno"
}

variable "chart_version" {
  description = "Kyverno Helm chart version."
  type        = string
  default     = "3.8.1"
}
