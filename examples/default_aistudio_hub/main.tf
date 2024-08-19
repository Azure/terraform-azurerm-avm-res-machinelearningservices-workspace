terraform {
  required_version = "~> 1.5"
  required_providers {
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

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.

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

  key_vault = {
    create_new = true
  }

  storage_account = {
    create_new = true
  }

  aiservices = {
    create_new = true
  }

  log_analytics_workspace = {
    include    = false
    create_new = false
  }

  application_insights = {
    include    = false
    create_new = false
  }

  enable_telemetry = false
}
