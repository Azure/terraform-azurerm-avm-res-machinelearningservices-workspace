terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

locals {
  tags = {
    scenario = "default AI Foundry"
  }
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "example" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

locals {
  name = module.naming.machine_learning_workspace.name_unique
}


data "azurerm_client_config" "current" {}

resource "azurerm_storage_account" "example" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.example.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.example.name
}

resource "azurerm_key_vault" "example" {
  location            = azurerm_resource_group.example.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azapi_resource" "aiservice" {
  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  body = {
    properties = {
      publicNetworkAccess = "Enabled"
      apiProperties = {
        statisticsEnabled = false
      }
    }
    sku = {
      "name" : "S0",
    }
    kind = "AIServices"
  }
  location               = var.location
  name                   = module.naming.cognitive_account.name_unique
  parent_id              = azurerm_resource_group.example.id
  response_export_values = ["*"]

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "aihub" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                = azurerm_resource_group.example.location
  name                    = local.name
  resource_group_name     = azurerm_resource_group.example.name
  kind                    = "Hub"
  workspace_friendly_name = "AI Studio Hub"

  aiservices = {
    name                      = azapi_resource.aiservice.name
    resource_group_id         = azapi_resource.aiservice.parent_id
    create_service_connection = true
  }

  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = false
  }

  key_vault = {
    resource_id = azurerm_key_vault.example.id
  }

  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }

  enable_telemetry = var.enable_telemetry
  tags             = local.tags
}

