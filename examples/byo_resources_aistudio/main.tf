terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.14.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.115.0"
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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

resource "azurerm_storage_account" "example" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
}

resource "azurerm_key_vault" "example" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
}

resource "azapi_resource" "aiservice" {
  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  body = jsonencode({
    properties = {
      publicNetworkAccess = "Enabled" # Can't have private AI Services with private AI Studio hubs
      apiProperties = {
        statisticsEnabled = false
      }
    }
    sku = {
      "name" : "S0"
    }
    kind = "AIServices"
  })
  location               = azurerm_resource_group.this.location
  name                   = "ai-svc-${module.naming.storage_account.name_unique}"
  parent_id              = azurerm_resource_group.this.id
  response_export_values = ["*"]

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      # When the service connection to the AI Studio Hub is created, 
      # tags are added to this resource
      tags,
    ]
  }
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.

data "azurerm_client_config" "current" {}

locals {
  name = module.naming.machine_learning_workspace.name_unique
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "aihub" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location = azurerm_resource_group.this.location
  name     = local.name
  resource_group = {
    id   = azurerm_resource_group.this.id
    name = azurerm_resource_group.this.name
  }
  kind = "Hub"
  storage_account = {
    resource_id = azurerm_storage_account.example.id
    create_new  = false
  }

  key_vault = {
    resource_id = replace(azurerm_key_vault.example.id, "Microsoft.KeyVault", "Microsoft.Keyvault")
    create_new  = false
  }

  aiservices = {
    name              = azapi_resource.aiservice.name
    resource_group_id = azurerm_resource_group.this.id
    create_new        = false
    include           = true
  }

  project_for_hub = {
    create_new = false
  }

  application_insights = {
    create_new = false
    include    = false
  }

  log_analytics_workspace = {
    create_new = false
    include    = false
  }
}
