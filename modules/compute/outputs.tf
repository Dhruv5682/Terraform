output "frontend_app_id" { value = azurerm_linux_web_app.frontend.id }
output "backend_app_id" { value = azurerm_linux_web_app.backend.id }
output "backend_principal_id" { value = azurerm_linux_web_app.backend.identity[0].principal_id }
output "frontend_default_hostname" { value = azurerm_linux_web_app.frontend.default_hostname }
output "backend_default_hostname" { value = azurerm_linux_web_app.backend.default_hostname }
