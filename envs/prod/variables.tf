variable "environment" {
  type        = string
  description = "Environment name"
  default     = "prod"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "Central India"
}

variable "storageaccountname" {
  type        = string
  description = "Storage account name"
  default     = "salearnprod123585"
}

variable "rgname" {
  type        = string
  description = "Resource group name"
  default     = "rg-learn-prod-june-default"
}
