<!-- BEGIN_TF_DOCS -->
# Azure AI Hub

This example deploys the core aspects of the architecture depicted in the image below.

![An architecture diagram. At the top, a Managed VNet containing a compute instance, serverless compute, a managed online endpoint and AI project is depicted. A private endpoint within the Managed VNet connects to the Azure AI Studio hub. There are also private endpoints connecting an Azure Storage Account, Azure Key Vault and Azure Container Registry to the Managed VNet. Azure AI Services, Azure Open AI and, optionally, Azure AI Search are accessible within the Managed VNet as well. In the middle left, there is an Azure VNet labeled 'Your Azure VNet' which serves as a bridge between an on-premise network and Azure resources with various private endpoints.](https://learn.microsoft.com/en-us/azure/ai-studio/media/how-to/network/azure-ai-network-outbound.png)

This specifically includes:

- 1 Azure VNet
  - subnet named "private\_endpoints"
- 6 private DNS zones linked to the VNet
  - "privatelink.api.azureml.ms" for the AI Foundry Hub
  - "privatelink.notebooks.azure.net" for the AI Foundry Hub
  - "privatelink.vaultcore.azure.net" for Key Vault
  - "privatelink.blob.core.windows.net" for Storage Account (blob)
  - "privatelink.file.core.windows.net" for Storage Account (file)
  - "privatelink.azurecr.io" for Container Registry
- AI Foundry Hub workspace (private)
  - 1 private endpoint in the "private\_endpoints" subnet referencing both "privatelink.api.azureml.ms" and "privatelink.notebooks.azure.net" DNS zones
- Storage Account (private)
  -  1 private endpoint in the "private\_endpoints" subnet referencing the "privatelink.blob.core.windows.net" DNS zone and
  -  1 private endpoint in the "private\_endpoints" subnet referencing DNS zone "privatelink.file.core.windows.net"
- Key Vault (private)
  - 1 private endpoint in the "private\_endpoints" subnet, referencing the "privatelink.vaultcore.azure.net" DNS zone
- Azure Container Registry (private)
  - 1 private endpoint in the "private\_endpoints" subnet, referencing the "privatelink.azurecr.io" DNS zone
- App Insights and Log Analytics workspace
- AI Services + an AI Services Connection to the Hub

The managed VNet is not provisioned by default. In the unprovisioned state, you can see the outbound rules created in the Azure Portal or with the Azure CLI + machine learning extension `az ml workspace outbound-rule list --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE`. Since all possible provisioned resources are private, this collection should include one of type `PrivateEndpoint` for each of the following:

- Key Vault
- Storage Account: file (spark enabled)
- Storage Account: blob (spark enabled)
- Container Registry
- The AI Hub Workspace (spark enabled)

After the network is provisioned (either by adding compute or manually provisioning it with [the Azure CLI + machine learning extension](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-provision-network)), the private endpoints themselves will be created internally for AI Studio.

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

data "azurerm_client_config" "current" {}

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
  tags = {
    scenario = "Private AI Foundry Hub"
  }
}

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.7"

  address_space       = ["192.168.0.0/24"]
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  name                = module.naming.virtual_network.name_unique
  subnets = {
    private_endpoints = {
      name                              = "private_endpoints"
      address_prefixes                  = ["192.168.0.0/24"]
      private_endpoint_network_policies = "Disabled"
      service_endpoints                 = null
    }
  }
  tags = local.tags
}

module "private_dns_aml_api" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.api.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
}

module "private_dns_aml_notebooks" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.notebooks.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.notebooks.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
}

module "private_dns_keyvault_vault" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.notebooks.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
}

module "private_dns_storageaccount_blob" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.blob.core.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
}

module "private_dns_storageaccount_file" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.file.core.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
}

module "private_dns_containerregistry_registry" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.azurecr.io"
      vnetid       = module.virtual_network.resource.id
    }
  }
}

module "avm_res_containerregistry_registry" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "~> 0.4"

  location            = var.location
  name                = replace(module.naming.container_registry.name_unique, "-", "")
  resource_group_name = azurerm_resource_group.this.name
  private_endpoints = {
    registry = {
      name                          = "pe-containerregistry-regsitry"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_containerregistry_registry.resource_id]
      inherit_lock                  = false
    }
  }
  public_network_access_enabled = false
  tags                          = local.tags
  zone_redundancy_enabled       = false
}

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  location            = var.location
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
  private_endpoints = {
    vault = {
      name                          = "pe-keyvault-vault"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_keyvault_vault.resource_id]
      inherit_lock                  = false
    }
  }
  public_network_access_enabled = false
  tags                          = local.tags
}

module "avm_res_storage_storageaccount" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  location            = var.location
  name                = replace(module.naming.storage_account.name_unique, "-", "")
  resource_group_name = azurerm_resource_group.this.name
  # for idempotency
  blob_properties = {
    cors_rule = [{
      allowed_headers = ["*", ]
      allowed_methods = [
        "GET",
        "HEAD",
        "PUT",
        "DELETE",
        "OPTIONS",
        "POST",
        "PATCH",
      ]
      allowed_origins = [
        "https://mlworkspace.azure.ai",
        "https://ml.azure.com",
        "https://*.ml.azure.com",
        "https://ai.azure.com",
        "https://*.ai.azure.com",
      ]
      exposed_headers = [
        "*",
      ]
      max_age_in_seconds = 1800
    }]
  }
  enable_telemetry = var.enable_telemetry
  managed_identities = {
    system_assigned = true
  }
  network_rules = {
    bypass         = ["Logging", "Metrics", "AzureServices"]
    default_action = "Deny"
  }
  private_endpoints = {
    blob = {
      name                          = "pe-storage-blob"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = [module.private_dns_storageaccount_blob.resource_id]
      inherit_lock                  = false
    }
    file = {
      name                          = "pe-storage-file"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.private_dns_storageaccount_file.resource_id]
      inherit_lock                  = false
    }
  }
  public_network_access_enabled = false
  shared_access_key_enabled     = true
  tags                          = local.tags
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
  container_registry = {
    resource_id = module.avm_res_containerregistry_registry.resource_id
  }
  enable_telemetry = var.enable_telemetry
  is_private       = true
  key_vault = {
    resource_id = module.avm_res_keyvault_vault.resource_id
  }
  kind = "Hub"
  private_endpoints = {
    hub = {
      name                          = "pe-aistudio-hub"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aml_api.resource_id, module.private_dns_aml_notebooks.resource_id]
      inherit_lock                  = false
    }
  }
  storage_account = {
    resource_id = module.avm_res_storage_storageaccount.resource_id
  }
  workspace_friendly_name = "Private AI Studio Hub"
  workspace_managed_network = {
    isolation_mode = "AllowOnlyApprovedOutbound"
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

### <a name="module_ai_services"></a> [ai\_services](#module\_ai\_services)

Source: Azure/avm-res-cognitiveservices-account/azurerm

Version: 0.6.0

### <a name="module_aihub"></a> [aihub](#module\_aihub)

Source: ../../

Version:

### <a name="module_avm_res_containerregistry_registry"></a> [avm\_res\_containerregistry\_registry](#module\_avm\_res\_containerregistry\_registry)

Source: Azure/avm-res-containerregistry-registry/azurerm

Version: ~> 0.4

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: ~> 0.9

### <a name="module_avm_res_storage_storageaccount"></a> [avm\_res\_storage\_storageaccount](#module\_avm\_res\_storage\_storageaccount)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: ~> 0.4

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_private_dns_aml_api"></a> [private\_dns\_aml\_api](#module\_private\_dns\_aml\_api)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_aml_notebooks"></a> [private\_dns\_aml\_notebooks](#module\_private\_dns\_aml\_notebooks)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_containerregistry_registry"></a> [private\_dns\_containerregistry\_registry](#module\_private\_dns\_containerregistry\_registry)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_keyvault_vault"></a> [private\_dns\_keyvault\_vault](#module\_private\_dns\_keyvault\_vault)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_storageaccount_blob"></a> [private\_dns\_storageaccount\_blob](#module\_private\_dns\_storageaccount\_blob)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_storageaccount_file"></a> [private\_dns\_storageaccount\_file](#module\_private\_dns\_storageaccount\_file)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_virtual_network"></a> [virtual\_network](#module\_virtual\_network)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.7

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->