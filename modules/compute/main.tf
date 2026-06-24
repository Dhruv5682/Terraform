resource "azurerm_service_plan" "app_plan" {
  name                = var.app_plan_name
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "mi" {
  name                = "mi-backend-app"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}



resource "azurerm_role_assignment" "kv_secret_user" {
  scope                = var.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.mi.principal_id
}

resource "azurerm_key_vault_secret" "db_conn" {
  name         = "db-connection-string"
  value        = "Server=${var.mysql_fqdn};Database=mydb;Uid=${var.db_user};Pwd=${var.db_password};"
  key_vault_id = var.kv_id
  depends_on   = [azurerm_role_assignment.kv_secret_user]
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "db_pass" {
  name         = "db-password"
  value        = var.db_password
  key_vault_id = var.kv_id
  depends_on   = [azurerm_role_assignment.kv_secret_user]
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "db_url" {
  name         = "db-url"
  value        = "mysql://${var.db_user}:${var.db_password}@${var.mysql_fqdn}:3306/mydb"
  key_vault_id = var.kv_id
  depends_on   = [azurerm_role_assignment.kv_secret_user]
  tags         = var.tags
}

resource "azurerm_linux_web_app" "backend" {
  name                = var.backend_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_plan.id
  tags                = var.tags

  virtual_network_subnet_id = var.appservice_subnet_id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mi.id]
  }

  site_config {
    application_stack {
      docker_image_name   = "dhruvsimform25/backend:latest"
      docker_registry_url = "https://index.docker.io"
    }
    vnet_route_all_enabled                        = true
  }

  app_settings = {
    "DOCKER_ENABLE_CI"                      = "true"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "DB_CONNECTION_STRING"                  = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_conn.versionless_id})"
    "DATABASE_URL"                          = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_url.versionless_id})"
    "DB_HOST"                               = var.mysql_fqdn
    "DB_USER"                               = var.db_user
    "DB_PASSWORD"                           = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_pass.versionless_id})"
    "DB_DATABASE"                           = "mydb"
    "DB_NAME"                               = "mydb"
    "DB_SSL"                                = "true"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
  }

  key_vault_reference_identity_id = azurerm_user_assigned_identity.mi.id
}

resource "azurerm_linux_web_app" "frontend" {
  name                = var.frontend_app_name
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_plan.id
  tags                = var.tags

  virtual_network_subnet_id = var.appservice_subnet_id

  identity {
    type         = "UserAssigned" 
    identity_ids = [azurerm_user_assigned_identity.mi.id] # Using same MI for ACR pull
  }

  site_config {
    application_stack {
      docker_image_name   = "dhruvsimform25/frontend:latest"
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    "DOCKER_ENABLE_CI"                      = "true"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"   = "false"
    "BACKEND_URL"                           = "https://${azurerm_linux_web_app.backend.default_hostname}"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
  }
}

resource "azurerm_monitor_diagnostic_setting" "backend_diag" {
  name                       = "backend-diag"
  target_resource_id         = azurerm_linux_web_app.backend.id
  log_analytics_workspace_id = var.log_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceAppLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "frontend_diag" {
  name                       = "frontend-diag"
  target_resource_id         = azurerm_linux_web_app.frontend.id
  log_analytics_workspace_id = var.log_workspace_id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
  }
  enabled_log {
    category = "AppServiceAppLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_action_group" "email_ag" {
  name                = "email-action-group"
  resource_group_name = var.resource_group_name
  short_name          = "emailag"
  tags                = var.tags

  email_receiver {
    name                    = "admin_email"
    email_address           = "sukhadiyadhruv35@gmail.com"
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_metric_alert" "frontend_requests_alert" {
  name                = "frontend-requests-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_linux_web_app.frontend.id]
  description         = "Alert when HTTP requests hit 50"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT1M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThanOrEqual"
    threshold        = 50
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_ag.id
  }
}

resource "azurerm_monitor_metric_alert" "plan_cpu_alert" {
  name                = "plan-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_service_plan.app_plan.id]
  description         = "Alert when CPU exceeds 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "CpuPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_ag.id
  }
}

resource "azurerm_monitor_metric_alert" "plan_memory_alert" {
  name                = "plan-memory-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_service_plan.app_plan.id]
  description         = "Alert when Memory exceeds 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "MemoryPercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_ag.id
  }
}

resource "azurerm_monitor_metric_alert" "plan_disk_queue_alert" {
  name                = "plan-disk-queue-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_service_plan.app_plan.id]
  description         = "Alert when Disk Queue Length exceeds 10"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Web/serverfarms"
    metric_name      = "DiskQueueLength"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_ag.id
  }
}
