<!-- BEGIN_TF_DOCS -->
# Deploy to existing resource group

This example provisions a publicly-accessible AML workspace with basic configuration that is deployed to an existing resource group. It can be used to demonstrate how to force purge of deleted workspaces, in contrast to the default behavior of a "soft delete". The "soft delete" results in the inability to create a new workspace with the same name until the workspace is purged.

## Verify the change in behavior

### Default: purge protection

1. `terraform apply -var "resource_group_name=<resource group name>"`
2. `terraform destroy -var "resource_group_name=<resource group name>" -target="module.azureml"` Plan shows only 1 resource to delete. Destroy succeeds.
3. `terraform apply -var "resource_group_name=<resource group name>"`. Plan shows only 1 resource to create. Apply fails with message "Soft-deleted workspace exists. Please purge or recover it."

### Force purge

1. `terraform apply -var "resource_group_name=<resource group name>" -var "force_purge_on_delete=true"`
2. `terraform destroy -var "resource_group_name=<resource group name>" -var "force_purge_on_delete=true" -target="module.azureml"` Plan shows only 1 resource to delete. Destroy succeeds.
3. `terraform apply -var "resource_group_name=<resource group name>" -var "force_purge_on_delete=true"`. Plan shows only 1 resource to create. Apply succeeds.

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
data "azurerm_resource_group" "this" {
  name = var.resource_group_name
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
  location                 = data.azurerm_resource_group.this.location
  name                     = module.naming.storage_account.name_unique
  resource_group_name      = data.azurerm_resource_group.this.name
  tags                     = local.tags
}

resource "azurerm_key_vault" "example" {
  location            = data.azurerm_resource_group.this.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.tags
}

resource "azurerm_container_registry" "example" {
  location            = data.azurerm_resource_group.this.location
  name                = module.naming.container_registry.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "Premium"
  tags                = local.tags
}

resource "azurerm_application_insights" "example" {
  application_type    = "web"
  location            = data.azurerm_resource_group.this.location
  name                = module.naming.application_insights.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = local.tags
  workspace_id        = azurerm_log_analytics_workspace.example.id
}

resource "azurerm_log_analytics_workspace" "example" {
  location            = data.azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = data.azurerm_resource_group.this.name
  tags                = local.tags
}

# This is the module call
module "azureml" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = data.azurerm_resource_group.this.location
  name                = module.naming.machine_learning_workspace.name_unique
  resource_group_name = data.azurerm_resource_group.this.name

  managed_identities = {
    system_assigned = true
  }

  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }

  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }

  key_vault = {
    resource_id = replace(azurerm_key_vault.example.id, "Microsoft.KeyVault", "Microsoft.Keyvault")
  }

  container_registry = {
    resource_id = azurerm_container_registry.example.id
  }

  application_insights = {
    resource_id = replace(azurerm_application_insights.example.id, "Microsoft.Insights", "Microsoft.insights")
  }

  tags             = local.tags
  enable_telemetry = var.enable_telemetry

  force_purge_on_delete = var.force_purge_on_delete
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azurerm_application_insights.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_insights) (resource)
- [azurerm_container_registry.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) (resource)
- [azurerm_key_vault.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_log_analytics_workspace.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_storage_account.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of an existing resource group.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `false`

### <a name="input_force_purge_on_delete"></a> [force\_purge\_on\_delete](#input\_force\_purge\_on\_delete)

Description: Whether to force purge when the workspace is destroyed. When `false`, a soft delete is performed. When `true`, the workspace is fully deleted.

Type: `bool`

Default: `false`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The output of the AVM module for the created AML workspace

## Modules

The following Modules are called:

### <a name="module_azureml"></a> [azureml](#module\_azureml)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

<!-- markdownlint-disable-next-line MD041 -->

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->