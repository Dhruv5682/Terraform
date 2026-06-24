resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.appgw_name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
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

resource "azurerm_web_application_firewall_policy" "waf" {
  name                = "${var.appgw_name}-wafpolicy"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  policy_settings {
    enabled = true
    mode    = "Prevention"
  }

  custom_rules {
    name      = "RateLimit50"
    priority  = 1
    rule_type = "RateLimitRule"
    action    = "Block"

    rate_limit_duration  = "OneMin"
    rate_limit_threshold = 50
    group_rate_limit_by  = "ClientAddr"

    match_conditions {
      match_variables {
        variable_name = "RemoteAddr"
      }
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["0.0.0.0/0", "::/0"]
    }
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

resource "azurerm_application_gateway" "network" {
  name                = var.appgw_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  firewall_policy_id  = azurerm_web_application_firewall_policy.waf.id

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
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
    name               = local.request_routing_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.listener_name
    url_path_map_name  = local.url_path_map_name
    priority           = 100
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

resource "azurerm_monitor_metric_alert" "appgw_5xx_alert" {
  name                = "appgw-5xx-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_gateway.network.id]
  description         = "Alert when HTTP 5xx errors are greater than 5"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "ResponseStatus"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 5

    dimension {
      name     = "HttpStatusGroup"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = var.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "appgw_4xx_alert" {
  name                = "appgw-4xx-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_gateway.network.id]
  description         = "Alert when HTTP 4xx errors are greater than 20"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "ResponseStatus"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 20

    dimension {
      name     = "HttpStatusGroup"
      operator = "Include"
      values   = ["4xx"]
    }
  }

  action {
    action_group_id = var.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "appgw_latency_alert" {
  name                = "appgw-latency-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_application_gateway.network.id]
  description         = "Alert when total response time is greater than 3 seconds"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "ApplicationGatewayTotalTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 3000 # 3000 ms = 3 seconds
  }

  action {
    action_group_id = var.action_group_id
  }
}
