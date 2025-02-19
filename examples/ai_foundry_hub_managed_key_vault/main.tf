terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
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

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

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
  name = module.naming.machine_learning_workspace.name_unique
  tags = {
    scenario = "AI Foundry with Managed Key Vault"
  }
}

module "ai_services" {
  source                             = "Azure/avm-res-cognitiveservices-account/azurerm"
  version                            = "0.6.0"
  resource_group_name                = azurerm_resource_group.this.name
  kind                               = "AIServices"
  name                               = module.naming.cognitive_account.name_unique
  location                           = var.location
  enable_telemetry                   = var.enable_telemetry
  sku_name                           = "S0"
  public_network_access_enabled      = true # required for AI Foundry
  local_auth_enabled                 = true
  outbound_network_access_restricted = false
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
  location            = azurerm_resource_group.this.location
  name                = local.name
  resource_group_name = azurerm_resource_group.this.name
  kind                = "Hub"
  key_vault           = { use_microsoft_managed_key_vault = true }
  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }
  workspace_friendly_name = "AI Studio Hub"
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }

  aiservices = {
    resource_group_id         = azurerm_resource_group.this.id
    name                      = module.ai_services.name
    create_service_connection = true
  }

  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}
