variable "name" {
  type        = string
  default     = "rgfortest2"
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
variable "tags" { type = map(string) }
