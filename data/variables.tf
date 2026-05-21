variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "polandcentral"
}

variable "resource_group_name" {
  description = "Resource group for data resources."
  type        = string
  default     = "rg-diploma-data"
}

variable "server_name" {
  description = "Name of the PostgreSQL Flexible Server (globally unique)."
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "admin_username" {
  description = "Postgres administrator username."
  type        = string
  default     = "diploma_admin"
}

variable "environments" {
  description = "Per-environment Kubernetes namespaces and database names."
  type = map(object({
    database = string
  }))
  default = {
    dev  = { database = "bank_dev" }
    test = { database = "bank_test" }
    prod = { database = "bank_prod" }
  }
}
