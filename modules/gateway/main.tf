resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.appgw_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_address_pool_name      = "${var.appgw_name}-beap"
  frontend_port_name             = "${var.appgw_name}-feport"
  frontend_ip_configuration_name = "${var.appgw_name}-feip"
  http_setting_name              = "${var.appgw_name}-be-htst"
  listener_name                  = "${var.appgw_name}-httplstn"
  request_routing_rule_name      = "${var.appgw_name}-rqrt"
  redirect_configuration_name    = "${var.appgw_name}-rdrcfg"
  backend_address_pool_name_api  = "${var.appgw_name}-beap-api"
  http_setting_name_api          = "${var.appgw_name}-be-htst-api"
  url_path_map_name              = "${var.appgw_name}-url-map"
}

resource "azurerm_application_gateway" "network" {
  name                = var.appgw_name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = [var.frontend_app_hostname]
  }

  backend_address_pool {
    name  = local.backend_address_pool_name_api
    fqdns = [var.backend_app_hostname]
  }

  backend_http_settings {
    name                                = local.http_setting_name
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
  }

  backend_http_settings {
    name                                = local.http_setting_name_api
    cookie_based_affinity               = "Disabled"
    port                                = 80
    protocol                            = "Http"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "PathBasedRouting"
    http_listener_name         = local.listener_name
    url_path_map_name          = local.url_path_map_name
    priority                   = 100
  }

  url_path_map {
    name                               = local.url_path_map_name
    default_backend_address_pool_name  = local.backend_address_pool_name
    default_backend_http_settings_name = local.http_setting_name

    path_rule {
      name                       = "api-rule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = local.backend_address_pool_name_api
      backend_http_settings_name = local.http_setting_name_api
    }
  }
}
