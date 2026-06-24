variable "location" {}
variable "resource_group_name" {}
variable "app_plan_name" {}
variable "frontend_app_name" {}
variable "backend_app_name" {}

variable "appservice_subnet_id" {}
# variable "kv_id" {}
# variable "kv_uri" {}
variable "mysql_fqdn" {}
variable "db_user" {}
variable "db_password" { sensitive = true }
variable "tags" { type = map(string) }
variable "app_insights_connection_string" {}
variable "log_workspace_id" {}
