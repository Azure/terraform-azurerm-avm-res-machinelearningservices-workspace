terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.14.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.115"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "0.3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}
