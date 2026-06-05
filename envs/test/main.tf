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

module "resourcegroup" {
  source      = "../../modules/resourcegroup"
  name        = var.rgname
  location    = var.location
  environment = var.environment
}

module "storageaccount" {
  source              = "../../modules/storageaccount"
  name                = var.storageaccountname
  resource_group_name = module.resourcegroup.name
  location            = var.location
  environment         = var.environment
}
