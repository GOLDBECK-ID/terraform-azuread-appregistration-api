terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.0"
    }
  }
}
