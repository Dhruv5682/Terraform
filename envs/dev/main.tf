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

module "resourcegroup" {
  source      = "../../modules/resourcegroup"
  name        = var.rgname
  location    = var.location
  environment = var.environment
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
  acr_name                 = "acrwebappdev${random_string.suffix.result}"
  kv_name                  = "kv-webapp-${random_string.suffix.result}"
  log_workspace_name       = "law-webapp-dev"
  app_insights_name        = "appi-webapp-dev"
}

module "database" {
  source              = "../../modules/database"
  location            = var.location
  resource_group_name = module.resourcegroup.namee
  vnet_id             = module.infrastructure.vnet_id
  pe_subnet_id        = module.infrastructure.pe_subnet_id
  mysql_server_name   = "mysql-webapp-${random_string.suffix.result}"
  admin_username      = var.db_admin_user
  admin_password      = var.db_admin_password
}

module "compute" {
  source               = "../../modules/compute"
  location             = var.location
  resource_group_name  = module.resourcegroup.namee
  app_plan_name        = "plan-webapp-dev"
  frontend_app_name    = "app-frontend-${random_string.suffix.result}"
  backend_app_name     = "app-backend-${random_string.suffix.result}"
  acr_login_server     = module.infrastructure.acr_login_server
  acr_id               = module.infrastructure.acr_id
  appservice_subnet_id = module.infrastructure.appservice_subnet_id
  kv_id                = module.infrastructure.kv_id
  kv_uri               = module.infrastructure.kv_uri
  mysql_fqdn           = module.database.mysql_server_fqdn
  db_user              = var.db_admin_user
  db_password          = var.db_admin_password
}

module "gateway" {
  source                = "../../modules/gateway"
  location              = var.location
  resource_group_name   = module.resourcegroup.namee
  appgw_name            = "agw-webapp-dev"
  appgw_subnet_id       = module.infrastructure.appgw_subnet_id
  frontend_app_hostname = module.compute.frontend_default_hostname
  backend_app_hostname  = module.compute.backend_default_hostname
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}
