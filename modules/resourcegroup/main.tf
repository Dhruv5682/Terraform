resource "azurerm_resource_group" "example" {
  name     = var.name
  location = var.location

  tags = {
    environment = var.environment
    name        = var.name
  }
}
