terraform {
  required_version = "=1.6.4"
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}