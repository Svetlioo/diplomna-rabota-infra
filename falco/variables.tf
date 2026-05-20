variable "namespace" {
  description = "Namespace to install Falco into."
  type        = string
  default     = "falco"
}

variable "chart_version" {
  description = "Falco Helm chart version."
  type        = string
  default     = "8.0.5"
}
