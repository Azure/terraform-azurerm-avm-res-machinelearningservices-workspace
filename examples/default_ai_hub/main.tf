terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.6"
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

data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "current" {}

# This is required for resource modules
resource "azurerm_resource_group" "example" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

data "azurerm_role_definition" "connection_approver" {
  name = "Azure AI Enterprise Network Connection Approver"
}

resource "azurerm_role_assignment" "connection_approver" {
  principal_id       = data.azurerm_client_config.current.object_id
  scope              = azurerm_resource_group.example.id
  role_definition_id = "${data.azurerm_subscription.primary.id}${data.azurerm_role_definition.connection_approver.id}"
}

locals {
  tags = {
    scenario = "default AI Hub"
  }
}

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

module "ai_services" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.10.0"

  kind                               = "AIServices"
  location                           = var.location
  name                               = module.naming.cognitive_account.name_unique
  resource_group_name                = azurerm_resource_group.example.name
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
  location            = azurerm_resource_group.example.location
  name                = "hub${random_string.name.id}"
  resource_group_name = azurerm_resource_group.example.name
  enable_telemetry    = var.enable_telemetry
  key_vault = {
    resource_id = azurerm_key_vault.example.id
  }
  kind                          = "Hub"
  public_network_access_enabled = true
  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }
  tags                    = local.tags
  workspace_friendly_name = "AI Studio Hub"
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = false
  }
}

resource "azapi_resource" "aiservices_connection" {
  name      = "sc${random_string.name.id}"
  parent_id = module.aihub.resource_id
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-07-01-preview"
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

