terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.70.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  common_tags = {
    environment = var.environment
    region      = var.location
  }
}

module "resourcegroup" {
  source      = "../../modules/resourcegroup"
  name        = var.rgname
  location    = var.location
  environment = var.environment
  tags        = local.common_tags
}

module "infrastructure" {
  source                   = "../../modules/infrastructure"
  location                 = var.location
  resource_group_name      = module.resourcegroup.namee
  vnet_name                = var.vnet_name
  address_space            = ["10.1.0.0/16"]
  appgw_subnet_prefix      = "10.1.1.0/24"
  appservice_subnet_prefix = "10.1.2.0/24"
  pe_subnet_prefix         = "10.1.3.0/24"

  kv_name            = "${var.kv_name}-${random_string.suffix.result}"
  log_workspace_name = var.log_workspace_name
  app_insights_name  = var.app_insights_name
  tags               = local.common_tags
}

module "database" {
  source              = "../../modules/database"
  location            = var.location
  resource_group_name = module.resourcegroup.namee
  vnet_id             = module.infrastructure.vnet_id
  pe_subnet_id        = module.infrastructure.pe_subnet_id
  mysql_server_name   = "${var.mysql_server_name}-${random_string.suffix.result}"
  admin_username      = var.db_admin_user
  admin_password      = var.db_admin_password
  tags                = local.common_tags
  action_group_id     = module.compute.action_group_id
}

module "compute" {
  source              = "../../modules/compute"
  location            = var.location
  resource_group_name = module.resourcegroup.namee
  app_plan_name       = var.app_plan_name
  frontend_app_name   = "${var.frontend_app_name}-${random_string.suffix.result}"
  backend_app_name    = "${var.backend_app_name}-${random_string.suffix.result}"

  appservice_subnet_id = module.infrastructure.appservice_subnet_id
  #   kv_id                          = module.infrastructure.kv_id
  #   kv_uri                         = module.infrastructure.kv_uri
  mysql_fqdn                     = module.database.mysql_server_fqdn
  db_user                        = var.db_admin_user
  db_password                    = var.db_admin_password
  app_insights_connection_string = module.infrastructure.app_insights_connection_string
  log_workspace_id               = module.infrastructure.log_workspace_id
  tags                           = local.common_tags
}

module "gateway" {
  source                = "../../modules/gateway"
  location              = var.location
  resource_group_name   = module.resourcegroup.namee
  appgw_name            = var.appgw_name
  appgw_subnet_id       = module.infrastructure.appgw_subnet_id
  frontend_app_hostname = module.compute.frontend_default_hostname
  backend_app_hostname  = module.compute.backend_default_hostname
  tags                  = local.common_tags
  action_group_id       = module.compute.action_group_id
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# module "policy" {
#   source                   = "../../modules/policy"
#   resource_group_id        = module.resourcegroup.ids
#   location                 = var.location
#   allowed_app_service_skus = ["B1", "B2", "B3"]
# }

resource "azurerm_consumption_budget_resource_group" "budget" {
  name              = "budget-${var.environment}-${local.common_tags.region}"
  resource_group_id = module.resourcegroup.ids

  amount     = 100
  time_grain = "Monthly"

  time_period {
    start_date = "2026-06-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80.0
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = ["sukhadiyadhruv35@gmail.com"]
  }

  lifecycle {
    ignore_changes = [time_period]
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_portal_dashboard" "dev_dashboard" {
  name                = "dashboard-webapp-${var.environment}-${local.common_tags.region}"
  resource_group_name = module.resourcegroup.namee
  location            = var.location
  tags                = local.common_tags

  dashboard_properties = jsonencode({
    "lenses" : {
      "0" : {
        "order" : 1,
        "parts" : {
          "0" : {
            "position" : { "x" : 0, "y" : 0, "rowSpan" : 2, "colSpan" : 12 },
            "metadata" : {
              "type" : "Extension/HubsExtension/PartType/MarkdownPart",
              "inputs" : [],
              "settings" : {
                "content" : {
                  "settings" : {
                    "content" : "This dashboard tracks the core metrics mapped to your active alerts. It monitors performance across Application Gateway, App Services, and MySQL Database in the **${var.environment}** environment.",
                    "title" : "📊 Webapp Infrastructure Monitoring",
                    "subtitle" : "Metrics"
                  }
                }
              }
            }
          },
          "1" : {
            "position" : { "x" : 0, "y" : 2, "rowSpan" : 4, "colSpan" : 4 },
            "metadata" : {
              "type" : "Extension/HubsExtension/PartType/MonitorChartPart",
              "inputs" : [
                {
                  "name" : "options",
                  "isOptional" : true,
                  "value" : {
                    "chart" : {
                      "metrics" : [
                        {
                          "resourceMetadata" : { "id" : module.compute.app_plan_id },
                          "name" : "CpuPercentage",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.web/serverfarms",
                          "metricVisualization" : { "displayName" : "CPU Percentage" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.app_plan_id },
                          "name" : "MemoryPercentage",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.web/serverfarms",
                          "metricVisualization" : { "displayName" : "Memory Percentage" }
                        }
                      ],
                      "title" : "App Service Plan Metrics",
                      "titleKind" : 1,
                      "visualization" : { "chartType" : 2 }
                    }
                  }
                },
                {
                  "name" : "sharedTimeRange",
                  "isOptional" : true
                }
              ]
            }
          },
          "2" : {
            "position" : { "x" : 4, "y" : 2, "rowSpan" : 4, "colSpan" : 4 },
            "metadata" : {
              "type" : "Extension/HubsExtension/PartType/MonitorChartPart",
              "inputs" : [
                {
                  "name" : "options",
                  "isOptional" : true,
                  "value" : {
                    "chart" : {
                      "metrics" : [
                        {
                          "resourceMetadata" : { "id" : module.database.mysql_server_id },
                          "name" : "cpu_percent",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.dbformysql/flexibleservers",
                          "metricVisualization" : { "displayName" : "CPU Percent" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.database.mysql_server_id },
                          "name" : "active_connections",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.dbformysql/flexibleservers",
                          "metricVisualization" : { "displayName" : "Active Connections" }
                        }
                      ],
                      "title" : "MySQL Database Metrics",
                      "titleKind" : 1,
                      "visualization" : { "chartType" : 2 }
                    }
                  }
                },
                {
                  "name" : "sharedTimeRange",
                  "isOptional" : true
                }
              ]
            }
          },
          "3" : {
            "position" : { "x" : 8, "y" : 2, "rowSpan" : 4, "colSpan" : 4 },
            "metadata" : {
              "type" : "Extension/HubsExtension/PartType/MonitorChartPart",
              "inputs" : [
                {
                  "name" : "options",
                  "isOptional" : true,
                  "value" : {
                    "chart" : {
                      "metrics" : [
                        {
                          "resourceMetadata" : { "id" : module.gateway.appgw_id },
                          "name" : "ResponseStatus",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.network/applicationgateways",
                          "metricVisualization" : { "displayName" : "Response Status" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.gateway.appgw_id },
                          "name" : "ApplicationGatewayTotalTime",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.network/applicationgateways",
                          "metricVisualization" : { "displayName" : "Total Time" }
                        }
                      ],
                      "title" : "Application Gateway Metrics",
                      "titleKind" : 1,
                      "visualization" : { "chartType" : 2 }
                    }
                  }
                },
                {
                  "name" : "sharedTimeRange",
                  "isOptional" : true
                }
              ]
            }
          },
          "4" : {
            "position" : { "x" : 0, "y" : 6, "rowSpan" : 4, "colSpan" : 6 },
            "metadata" : {
              "type" : "Extension/HubsExtension/PartType/MonitorChartPart",
              "inputs" : [
                {
                  "name" : "options",
                  "isOptional" : true,
                  "value" : {
                    "chart" : {
                      "metrics" : [
                        {
                          "resourceMetadata" : { "id" : module.compute.frontend_app_id },
                          "name" : "Http5xx",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "HTTP 5xx" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.frontend_app_id },
                          "name" : "Http4xx",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "HTTP 4xx" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.frontend_app_id },
                          "name" : "AverageResponseTime",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "Avg Response Time" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.frontend_app_id },
                          "name" : "Requests",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "Requests" }
                        }
                      ],
                      "title" : "Frontend App Metrics",
                      "titleKind" : 1,
                      "visualization" : { "chartType" : 2 }
                    }
                  }
                },
                {
                  "name" : "sharedTimeRange",
                  "isOptional" : true
                }
              ]
            }
          },
          "5" : {
            "position" : { "x" : 6, "y" : 6, "rowSpan" : 4, "colSpan" : 6 },
            "metadata" : {
              "type" : "Extension/HubsExtension/PartType/MonitorChartPart",
              "inputs" : [
                {
                  "name" : "options",
                  "isOptional" : true,
                  "value" : {
                    "chart" : {
                      "metrics" : [
                        {
                          "resourceMetadata" : { "id" : module.compute.backend_app_id },
                          "name" : "Http5xx",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "HTTP 5xx" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.backend_app_id },
                          "name" : "Http4xx",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "HTTP 4xx" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.backend_app_id },
                          "name" : "AverageResponseTime",
                          "aggregationType" : 4,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "Avg Response Time" }
                        },
                        {
                          "resourceMetadata" : { "id" : module.compute.backend_app_id },
                          "name" : "Requests",
                          "aggregationType" : 1,
                          "namespace" : "microsoft.web/sites",
                          "metricVisualization" : { "displayName" : "Requests" }
                        }
                      ],
                      "title" : "Backend App Metrics",
                      "titleKind" : 1,
                      "visualization" : { "chartType" : 2 }
                    }
                  }
                },
                {
                  "name" : "sharedTimeRange",
                  "isOptional" : true
                }
              ]
            }
          }
        }
      }
    },
    "metadata" : {
      "model" : {
        "timeRange" : {
          "value" : {
            "relative" : {
              "duration" : 24,
              "timeUnit" : 1
            }
          },
          "type" : "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  })
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     