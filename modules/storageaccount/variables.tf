variable "name" {
  type        = string
  description = "Storage account name"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name for the storage account"
}

variable "location" {
  type        = string
  description = "Azure region for the storage account"
}

variable "environment" {
  type        = string
  description = "Environment name used for tagging"
}
