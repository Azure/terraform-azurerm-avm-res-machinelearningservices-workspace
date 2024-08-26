terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.115.0"
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

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
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

locals {
  name = module.naming.machine_learning_workspace.name_unique
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "azureml" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location                = azurerm_resource_group.this.location
  name                    = local.name
  resource_group_name     = azurerm_resource_group.this.name
  is_private              = true
  workspace_friendly_name = "private-aml-workspace"
  workspace_description   = "A private AML workspace"

  workspace_managed_network = {
    isolation_mode = "AllowInternetOutbound"
  }

  container_registry = {
    create_new     = true
    zone_redundant = false
  }

  application_insights = {
    create_new = true
    log_analytics_workspace = {
      create_new = true
    }
  }

  enable_telemetry = false
}