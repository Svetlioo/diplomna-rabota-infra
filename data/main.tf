resource "azurerm_resource_group" "data" {
  name     = var.resource_group_name
  location = var.location
}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = var.server_name
  resource_group_name           = azurerm_resource_group.data.name
  location                      = azurerm_resource_group.data.location
  version                       = var.postgres_version
  administrator_login           = var.admin_username
  administrator_password        = random_password.admin.result
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  storage_tier                  = "P4"
  public_network_access_enabled = true
  zone                          = "1"

  authentication {
    password_auth_enabled = true
  }
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "envs" {
  for_each  = var.environments
  name      = each.value.database
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "kubernetes_secret_v1" "account_db" {
  for_each = var.environments

  metadata {
    name      = "account-service-db"
    namespace = each.key
  }

  data = {
    SPRING_DATASOURCE_URL      = "jdbc:postgresql://${azurerm_postgresql_flexible_server.main.fqdn}:5432/${each.value.database}?sslmode=require"
    SPRING_DATASOURCE_USERNAME = var.admin_username
    SPRING_DATASOURCE_PASSWORD = random_password.admin.result
  }

  type = "Opaque"
}
