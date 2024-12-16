<!-- BEGIN_TF_DOCS -->
# Encryption with customer-managed key

This deploys the module with a public workspace set to be encrypted with a provided customer-managed key.

Pre-created resources include:

- Key Vault
- An RSA Key

The module creates:

- an Azure Machine Learning Workspace
  - a new Storage Account
  - new App. Insights & Log Analytics Workspace
  - The workspace uses the Key Vault pre-created and is encrypted with the pre-created RSA key

To support encryption with a customer-managed key, a Microsoft-managed resource group is created. It is named using the following convention `azureml-rg-<workspace-name>_<random GUID>`. Within it, are the follow resources:

- AI Search Service: Stores indexes that help with querying machine learning content.
- Cosmos DB Account: Stores job history data, compute metadata, and asset metadata
- Storage Account: Stores metadata related to Azure Machine Learning pipeline data.

```hcl
terraform {
  required_version = "~> 1.9"
  required_providers {
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
  storage_use_azuread = true
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

locals {
  cosmos_db_id = "a232010e-820c-4083-83bb-3ace5fc29d0b" # **FOR AZURE GOV** use "57506a73-e302-42a9-b869-6f12d9ec29e9"
}

# create a keyvault for storing the credential with RBAC for the deployment user
module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "~> 0.9.1"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }

    cosmos_db = {
      role_definition_id_or_name       = "Key Vault Crypto Service Encryption User"
      principal_id                     = local.cosmos_db_id
      skip_service_principal_aad_check = true # because it isn't a traditional SP
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
}

# create a Customer Managed Key for a Storage Account.
resource "azurerm_key_vault_key" "cmk" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  key_type     = "RSA"
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  name         = module.naming.key_vault_key.name_unique
  key_size     = 2048

  depends_on = [module.avm_res_keyvault_vault]
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
    create_new = true
    log_analytics_workspace = {
      create_new = true
    }
  }

  key_vault = {
    create_new  = false
    resource_id = module.avm_res_keyvault_vault.resource_id
  }

  managed_identities = {
    system_assigned = true
  }

  customer_managed_key = {
    key_name              = azurerm_key_vault_key.cmk.name
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
  }

  enable_telemetry = var.enable_telemetry

  depends_on = [azurerm_key_vault_key.cmk]
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_key_vault_key.cmk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_key) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
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

Default: `false`

### <a name="input_location"></a> [location](#input\_location)

Description: The location for the resources.

Type: `string`

Default: `"eastus2"`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The output of the module

## Modules

The following Modules are called:

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: ~> 0.9.1

### <a name="module_azureml"></a> [azureml](#module\_azureml)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.4

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->