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

locals {
  tags = {
    scenario = "diagnostic settings"
  }
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

data "azurerm_client_config" "current" {}

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

resource "azurerm_log_analytics_workspace" "diag" {
  location            = azurerm_resource_group.this.location
  name                = "diag${module.naming.log_analytics_workspace.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# This is the module call
module "azureml" {
  source = "../../"

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.machine_learning_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  application_insights = {
    resource_id = replace(azurerm_application_insights.example.id, "Microsoft.Insights", "Microsoft.insights")
  }
  container_registry = {
    resource_id = azurerm_container_registry.example.id
  }
  diagnostic_settings = {
    diag = {
      name                  = "aml${module.naming.monitor_diagnostic_setting.name_unique}"
      workspace_resource_id = azurerm_log_analytics_workspace.diag.id
    }
  }
  enable_telemetry = var.enable_telemetry
  key_vault = {
    resource_id = replace(azurerm_key_vault.example.id, "Microsoft.KeyVault", "Microsoft.Keyvault")
  }
  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }
  tags = local.tags
}
