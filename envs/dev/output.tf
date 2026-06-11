output "appgw_public_ip" {
  description = "The Public IP of the Application Gateway"
  value       = module.gateway.appgw_public_ip
}

output "frontend_default_hostname" {
  description = "The default hostname of the Frontend App Service"
  value       = module.compute.frontend_default_hostname
}

output "mysql_server_fqdn" {
  description = "The FQDN of the MySQL Flexible Server"
  value       = module.database.mysql_server_fqdn
}

output "acr_login_server" {
  description = "The login server for the Azure Container Registry"
  value       = module.infrastructure.acr_login_server
}
