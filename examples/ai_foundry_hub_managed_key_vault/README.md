<!-- BEGIN_TF_DOCS -->
# AI Foundry with managed Key Vault

This example demonstrates provisioning an AI Foundry Hub using a managed Key Vault instead of a user-managed instance.

The following resources are included:

- A storage account
- A publicly-accessible AI Foundry Hub
- An AI Services instance with a connection to the Hub

```hcl
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
  public_network_access_enabled      = true # required for AI Foundry
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
  aiservices = {
    resource_group_id         = azurerm_resource_group.this.id
    name                      = module.ai_services.name
    create_service_connection = true
  }
  enable_telemetry = var.enable_telemetry
  key_vault        = { use_microsoft_managed_key_vault = true }
  kind             = "Hub"
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)

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

### <a name="module_ai_services"></a> [ai\_services](#module\_ai\_services)

Source: Azure/avm-res-cognitiveservices-account/azurerm

Version: 0.6.0

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