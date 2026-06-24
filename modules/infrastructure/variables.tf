variable "location" {}
variable "resource_group_name" {}
variable "vnet_name" {}
variable "address_space" { type = list(string) }
variable "appgw_subnet_prefix" {}
variable "appservice_subnet_prefix" {}
variable "pe_subnet_prefix" {}

variable "kv_name" {}
variable "log_workspace_name" {}
variable "app_insights_name" {}
variable "tags" { type = map(string) }
