terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.9"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.71"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}