resource "azurerm_policy_definition" "require_tags" {
  name         = "require-env-region-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require environment and region tags"
  description  = "This policy requires the 'environment' and 'region' tags to be present on all resources."

  policy_rule = <<POLICY_RULE
{
  "if": {
    "anyOf": [
      {
        "field": "tags['environment']",
        "exists": "false"
      },
      {
        "field": "tags['region']",
        "exists": "false"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

resource "azurerm_resource_group_policy_assignment" "require_tags_assign" {
  name                 = "req-tags-assign"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  resource_group_id  = var.resource_group_id
}

resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations-custom"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Allowed locations"
  description  = "This policy enables you to restrict the locations your organization can specify when deploying resources."

  policy_rule = <<POLICY_RULE
{
  "if": {
    "not": {
      "field": "location",
      "in": "[parameters('allowedLocations')]"
    }
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "allowedLocations": {
    "type": "Array",
    "metadata": {
      "description": "The list of allowed locations for resources.",
      "displayName": "Allowed locations",
      "strongType": "location"
    }
  }
}
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "allowed_locations_assign" {
  name                 = "allowed-loc-assign"
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  resource_group_id  = var.resource_group_id
  parameters           = <<PARAMETERS
{
  "allowedLocations": {
    "value": ["${var.location}", "global"]
  }
}
PARAMETERS
}

resource "azurerm_policy_definition" "app_service_sku" {
  name         = "app-service-allowed-skus"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed App Service SKUs"
  description  = "This policy limits the SKUs that can be used for App Service Plans."

  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Web/serverfarms"
      },
      {
        "not": {
          "field": "Microsoft.Web/serverfarms/sku.name",
          "in": "[parameters('allowedSkus')]"
        }
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE

  parameters = <<PARAMETERS
{
  "allowedSkus": {
    "type": "Array",
    "metadata": {
      "description": "The list of allowed SKUs for App Service Plans.",
      "displayName": "Allowed SKUs"
    }
  }
}
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "app_service_sku_assign" {
  name                 = "app-svc-sku-assign"
  policy_definition_id = azurerm_policy_definition.app_service_sku.id
  resource_group_id  = var.resource_group_id
  parameters           = <<PARAMETERS
{
  "allowedSkus": {
    "value": ${jsonencode(var.allowed_app_service_skus)}
  }
}
PARAMETERS
}
