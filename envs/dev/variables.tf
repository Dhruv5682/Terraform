variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "Central India"
}

variable "storageaccountname" {
  type        = string
  description = "Storage account name"
  default     = "salearndev123585"
}

variable "rgname" {
  type        = string
  description = "Resource group name"
  default     = "rg-learn-dev-june-default"
}
