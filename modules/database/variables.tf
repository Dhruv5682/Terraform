variable "location" {}
variable "resource_group_name" {}
variable "mysql_server_name" {}
variable "admin_username" {}
variable "admin_password" { sensitive = true }
variable "vnet_id" {}
variable "pe_subnet_id" {}
