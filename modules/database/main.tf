resource "azurerm_private_dns_zone" "mysql_dns" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "null_resource" "seed_db" {
  depends_on = [azurerm_mysql_flexible_database.default_db]

  triggers = {
    db_id = azurerm_mysql_flexible_database.default_db.id
  }

  provisioner "local-exec" {
    command = <<EOT
      MY_IP=$(curl -s ifconfig.me)
      az mysql flexible-server firewall-rule create -g ${var.resource_group_name} -n ${azurerm_mysql_flexible_server.mysql.name} --rule-name temp-seed-rule --start-ip-address $MY_IP --end-ip-address $MY_IP
      
      sleep 15
      
      docker run --rm mysql:8.0 mysql -h ${azurerm_mysql_flexible_server.mysql.fqdn} -u ${var.admin_username} -p'${var.admin_password}' -e "USE mydb; DROP TABLE IF EXISTS items; CREATE TABLE items (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255), description TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO items (name, description) VALUES ('Item 1', 'Description for Item 1'), ('Item 2', 'Description for Item 2');"
      
      az mysql flexible-server firewall-rule delete -g ${var.resource_group_name} -n ${azurerm_mysql_flexible_server.mysql.name} --rule-name temp-seed-rule --yes
    EOT
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql_dns_link" {
  name                  = "mysql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_dns.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_mysql_flexible_server" "mysql" {
  name                   = var.mysql_server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_username
  administrator_password = var.admin_password
  sku_name               = "B_Standard_B1ms"
  version                = "8.0.21"
  zone                   = "1"
  tags                   = var.tags
  # sensitive     = true
}

resource "azurerm_mysql_flexible_database" "default_db" {
  name                = "mydb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.mysql.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_private_endpoint" "mysql_pe" {
  name                = "${var.mysql_server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.mysql_server_name}-privateserviceconnection"
    private_connection_resource_id = azurerm_mysql_flexible_server.mysql.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.mysql_dns.id]
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.mysql_dns_link]
}

resource "azurerm_monitor_metric_alert" "mysql_cpu_alert" {
  name                = "mysql-cpu-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_mysql_flexible_server.mysql.id]
  description         = "Alert when MySQL CPU usage exceeds 80%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "cpu_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = var.action_group_id
  }
}

resource "azurerm_monitor_metric_alert" "mysql_connections_alert" {
  name                = "mysql-connections-alert"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_mysql_flexible_server.mysql.id]
  description         = "Alert when MySQL active connections exceed 80"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.DBforMySQL/flexibleServers"
    metric_name      = "active_connections"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = var.action_group_id
  }
}
