resource "azurerm_storage_account" "example" {
  name                             = var.name
  resource_group_name              = var.resource_group_name
  location                         = var.location
  account_tier                     = "Standard"
  account_replication_type         = "LRS"
  account_kind                     = "BlobStorage"
  cross_tenant_replication_enabled = "true"
  access_tier                      = "Hot"
  public_network_access_enabled    = "true"


  tags = {
    environment = var.environment
    name        = var.name
  }
}
