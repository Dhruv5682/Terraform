terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# terraform {
#   backend "remote" {
#     path = "terraform.tfstate"
#   }
# }
