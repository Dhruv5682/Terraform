resource "azurerm_resource_group" "example" {
  name     = var.name
  location = var.location

  tags = merge(var.tags, {
    name = var.name
  })

  # lifecycle {
  #   prevent_destroy = var.environment == "prod" || var.environment == "Prod" ? true : false
  # }



}
