variable "environment" {
  type        = string
  description = "Environment name"
  default     = "test"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "Central India"
}

variable "storageaccountname" {
  type        = string
  description = "Storage account name"
  default     = "salearntest123683"
}

variable "rgname" {
  type        = string
  description = "Resource group name"
  default     = "rg-learn-test-june-default"
}
