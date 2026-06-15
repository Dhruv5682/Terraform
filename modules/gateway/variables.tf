variable "location" {}
variable "resource_group_name" {}
variable "appgw_name" {}
variable "appgw_subnet_id" {}
variable "frontend_app_hostname" {}
variable "backend_app_hostname" {}
variable "tags" { type = map(string) }
variable "action_group_id" {}
