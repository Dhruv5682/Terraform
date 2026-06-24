terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstatedevdhruv"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

# terraform {
#   backend "remote" {
#     path = "terraform.tfstate"
#   }
# }
