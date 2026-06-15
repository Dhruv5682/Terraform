output "frontend_app_id" { value = azurerm_linux_web_app.frontend.id }
output "backend_app_id" { value = azurerm_linux_web_app.backend.id }
output "backend_principal_id" { value = azurerm_linux_web_app.backend.identity[0].principal_id }
output "frontend_default_hostname" { value = azurerm_linux_web_app.frontend.default_hostname }
output "backend_default_hostname" { value = azurerm_linux_web_app.backend.default_hostname }
output "action_group_id" { value = azurerm_monitor_action_group.email_ag.id }
output "app_plan_id" { value = azurerm_service_plan.app_plan.id }
