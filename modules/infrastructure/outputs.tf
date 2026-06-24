output "vnet_id" { value = azurerm_virtual_network.vnet.id }
output "appgw_subnet_id" { value = azurerm_subnet.appgw.id }
output "appservice_subnet_id" { value = azurerm_subnet.appservice.id }
output "pe_subnet_id" { value = azurerm_subnet.pe.id }

output "kv_id" { value = azurerm_key_vault.kv.id }
output "kv_uri" { value = azurerm_key_vault.kv.vault_uri }
output "log_workspace_id" { value = azurerm_log_analytics_workspace.law.id }
output "app_insights_connection_string" { value = azurerm_application_insights.appinsights.connection_string }
