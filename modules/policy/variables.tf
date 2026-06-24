variable "resource_group_id" {
  type        = string
  description = "The scope to assign the policies (e.g. Resource Group ID)"
}

variable "location" {
  type        = string
  description = "The allowed location"
}

variable "allowed_app_service_skus" {
  type    = list(string)
  default = ["B1", "B2", "B3"]
}
