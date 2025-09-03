terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 3.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.42.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7.2"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.13.1"
    }
  }
}
