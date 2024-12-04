<!-- BEGIN_TF_DOCS -->
# BYO Resources - AI Studio

This deploys a public AI Studio Hub using existing resources. The resource group, storage account, key vault, and cognitive services account (AI Services) are all provided to the module.

```hcl
terraform {
  required_version = "~> 1.9"
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "1.15.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 4.0.0"
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
  body = jsonencode({
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
  })
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
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }

  aiservices = {
    create_new                = false
    name                      = azapi_resource.aiservice.name
    resource_group_id         = azapi_resource.aiservice.parent_id
    create_service_connection = true
  }

  key_vault = {
    create_new  = false
    resource_id = azurerm_key_vault.example.id
  }

  storage_account = {
    create_new  = false
    resource_id = azurerm_storage_account.example.id
  }

  enable_telemetry = var.enable_telemetry
}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (1.15.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azapi_resource.aiservice](https://registry.terraform.io/providers/Azure/azapi/1.15.0/docs/resources/resource) (resource)
- [azurerm_key_vault.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_location"></a> [location](#input\_location)

Description: The location for the resources.

Type: `string`

Default: `"australiaeast"`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The AI Studio hub workspace.

## Modules

The following Modules are called:

### <a name="module_aihub"></a> [aihub](#module\_aihub)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->