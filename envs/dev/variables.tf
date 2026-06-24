variable "location" {
  type        = string
  description = "Azure region"
  default     = "southeastasia"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "rgname" {
  type    = string
  default = "rg-webapp-dev"
}

variable "vnet_name" {
  type    = string
  default = "vnet-dev-sea"
}

variable "db_admin_user" {
  type    = string
  default = "mysqladmin"
}

variable "db_admin_password" {
  type      = string
  sensitive = true
}



variable "kv_name" {
  type    = string
  default = "kv-webapp-dev-sea"
}

variable "log_workspace_name" {
  type    = string
  default = "law-webapp-dev-sea"
}

variable "app_insights_name" {
  type    = string
  default = "appi-webapp-dev-sea"
}

variable "mysql_server_name" {
  type    = string
  default = "mysql-webapp-dev-sea"
}

variable "app_plan_name" {
  type    = string
  default = "plan-webapp-dev-sea"
}

variable "frontend_app_name" {
  type    = string
  default = "app-frontend-dev-sea"
}

variable "backend_app_name" {
  type    = string
  default = "app-backend-dev-sea"
}

variable "appgw_name" {
  type    = string
  default = "agw-webapp-dev-sea"
}
