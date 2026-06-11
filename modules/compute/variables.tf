variable "location" {}
variable "resource_group_name" {}
variable "app_plan_name" {}
variable "frontend_app_name" {}
variable "backend_app_name" {}
variable "acr_login_server" {}
variable "acr_id" {}
variable "appservice_subnet_id" {}
variable "kv_id" {}
variable "kv_uri" {}
variable "mysql_fqdn" {}
variable "db_user" {}
variable "db_password" { sensitive = true }
