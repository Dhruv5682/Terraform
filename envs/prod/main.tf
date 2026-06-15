terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.70.0"
    }
  }
}

provider "azurerm" {
  features {}
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


module "policy" {
  source                   = "../../modules/policy"
  resource_group_id        = module.resourcegroup.ids
  location                 = var.location
  allowed_app_service_skus = ["B1", "B2", "B3"]
}
