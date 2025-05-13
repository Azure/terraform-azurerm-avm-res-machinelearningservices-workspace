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
}

data "azurerm_client_config" "current" {}

locals {
  tags = {
    scenario = "default"
  }
}

resource "azurerm_storage_account" "example" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = azurerm_resource_group.this.name
  tags                     = local.tags
}

resource "azurerm_key_vault" "example" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
}

resource "azurerm_container_registry" "example" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.container_registry.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Premium"
  tags                = local.tags
}

resource "azurerm_application_insights" "example" {
  application_type    = "web"
  location            = azurerm_resource_group.this.location
  name                = module.naming.application_insights.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
  workspace_id        = azurerm_log_analytics_workspace.example.id
}

resource "azurerm_log_analytics_workspace" "example" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# This is the module call
module "azureml" {
  source = "../../"

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location          = azurerm_resource_group.this.location
  name              = module.naming.machine_learning_workspace.name_unique
  resource_group_id = azurerm_resource_group.this.id
  application_insights = {
    resource_id = replace(azurerm_application_insights.example.id, "Microsoft.Insights", "Microsoft.insights")
  }
  container_registry = {
    resource_id = azurerm_container_registry.example.id
  }
  enable_telemetry = var.enable_telemetry
  key_vault = {
    resource_id = replace(azurerm_key_vault.example.id, "Microsoft.KeyVault", "Microsoft.Keyvault")
  }
  managed_identities = {
    system_assigned = true
  }
  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }
  tags = local.tags
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }
}
