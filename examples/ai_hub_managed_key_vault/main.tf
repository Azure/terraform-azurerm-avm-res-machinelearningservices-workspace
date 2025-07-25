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
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_string" "name" {
  length  = 5
  numeric = false
  special = false
  upper   = false
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  unique-length = 5
  unique-seed   = random_string.name.id
}

data "azurerm_client_config" "current" {}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

resource "azurerm_storage_account" "example" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
  tags                     = local.tags
}

locals {
  tags = {
    scenario = "AI Hub with Managed Key Vault"
  }
}

resource "azurerm_role_assignment" "connection_approver" {
  principal_id       = data.azurerm_client_config.current.object_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/b556d68e-0be0-4f35-a333-ad7ee1ce17ea" #  Azure AI Enterprise Network Connection Approver
}

module "ai_services" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.6.0"

  kind                               = "AIServices"
  location                           = var.location
  name                               = module.naming.cognitive_account.name_unique
  resource_group_name                = azurerm_resource_group.this.name
  sku_name                           = "S0"
  enable_telemetry                   = var.enable_telemetry
  local_auth_enabled                 = true
  outbound_network_access_restricted = false
  public_network_access_enabled      = true
  tags                               = local.tags
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "aihub" {
  source = "../../"

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                      = azurerm_resource_group.this.location
  name                          = "hub${random_string.name.id}"
  resource_group_name           = azurerm_resource_group.this.name
  enable_telemetry              = var.enable_telemetry
  key_vault                     = { use_microsoft_managed_key_vault = true }
  kind                          = "Hub"
  public_network_access_enabled = true
  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }
  tags                    = local.tags
  workspace_friendly_name = "AI Studio Hub"
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }
}

resource "azapi_resource" "aiservices_connection" {
  name      = "sc${random_string.name.id}"
  parent_id = module.aihub.resource_id
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview"
  body = {
    properties = {
      category      = "AIServices"
      target        = module.ai_services.endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure",
        ResourceId = module.ai_services.resource_id
      }
    }
  }
}
