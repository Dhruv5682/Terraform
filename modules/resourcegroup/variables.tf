variable "name" {
  type        = string
  description = "Resource group name"
}

variable "location" {
  type        = string
  description = "Azure region for the resource group"
}

variable "environment" {
  type        = string
  description = "Environment name used for tagging"
}
