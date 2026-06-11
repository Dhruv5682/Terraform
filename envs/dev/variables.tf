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
