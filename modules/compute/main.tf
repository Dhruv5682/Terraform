resource "azurerm_service_plan" "app_plan" {
  name                = var.app_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_user_assigned_identity" "mi" {
  name                = "mi-backend-app"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Role assignment to allow Managed Identity to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Key Vault RBAC Role Assignment for MI
resource "azurerm_role_assignment" "kv_secret_user" {
  scope                = var.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

# Add a secret for DB Connection string in Key Vault
resource "azurerm_key_vault_secret" "db_conn" {
  name         = "db-connection-string"
  value        = "Server=${var.mysql_fqdn};Database=mydb;Uid=${var.db_user};Pwd=${var.db_password};"
  key_vault_id = var.kv_id
  depends_on   = [azurerm_role_assignment.kv_secret_user]
}

resource "azurerm_key_vault_secret" "db_pass" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = var.kv_id
  depends_on   = [azurerm_role_assignment.kv_secret_user]
}

resource "azurerm_key_vault_secret" "db_url" {
  name         = "db-url"
  value        = "mysql://${var.db_user}:${var.db_password}@${var.mysql_fqdn}:3306/mydb"
  key_vault_id = var.kv_id
  depends_on   = [azurerm_role_assignment.kv_secret_user]
}

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  virtual_network_subnet_id = var.appservice_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id]
  }

  site_config {
    application_stack {
      docker_image_name   = "backend:v1"
      docker_registry_url = "https://${var.acr_login_server}"
    }
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.mi.client_id
    vnet_route_all_enabled                        = true
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DB_CONNECTION_STRING"                = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_conn.versionless_id})"
    "DATABASE_URL"                        = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_url.versionless_id})"
    "DB_HOST"                             = var.mysql_fqdn
    "DB_USER"                             = var.db_user
    "DB_PASSWORD"                         = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_pass.versionless_id})"
    "DB_DATABASE"                         = "mydb"
    "DB_NAME"                             = "mydb"
    "DB_SSL"                              = "true"
  }

  key_vault_reference_identity_id = azurerm_user_assigned_identity.mi.id
}

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  # Frontend doesn't strictly need VNet integration unless it communicates with the backend via internal IPs
  # Let's enable it just in case
  virtual_network_subnet_id = var.appservice_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id] # Using same MI for ACR pull
  }

  site_config {
    application_stack {
      docker_image_name   = "frontend:v1"
      docker_registry_url = "https://${var.acr_login_server}"
    }
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.mi.client_id
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "BACKEND_URL"                         = "https://${azurerm_linux_web_app.backend.default_hostname}"
  }
}
