<!-- BEGIN_TF_DOCS -->
# Private AML workspace - BYO VNet

This example demonstrates provisioning a private AML workspace where network traffic is managed by the VNet it is deployed into instead of using the managed VNet.

The following resources are included:

- A VNet with a private endpoints subnet
- Private DNS zones
- Key Vault, Storage and Container Registry without public network access, connected to VNet with private endpoints
- Azure Monitor Private Link Scope (AMPLS) connected to the VNet with a private endpoint
- App. Insights and Log Analytics associated with the created AMPLS
- An AML Workspace which lacks public network access, is connected to the VNet with a private endpoint and has the workspace's managed VNet configured as "Disabled" which offloads inbound and outbound traffic management to a firewall associated with the VNet

\_**Note** no firewall is included with this example.\_ Please refer to [MS Learn: AML inbound and outbound network traffic configuration](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-access-azureml-behind-firewall?view=azureml-api-2&tabs=ipaddress%2Cpublic) for specific requirements for an AML workspace.

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

locals {
  tags = {
    scenario = "BYO VNet"
  }
}

data "azurerm_client_config" "current" {}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
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
      vnetid       = module.virtual_network.resource_id
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
      vnetid       = module.virtual_network.resource_id
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
      vnetid       = module.virtual_network.resource_id
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
      vnetid       = module.virtual_network.resource_id
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
      vnetid       = module.virtual_network.resource_id
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
      vnetid       = module.virtual_network.resource_id
    }
  }
}

module "private_dns_monitor" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.monitor.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.monitor.azure.com"
      vnetid       = module.virtual_network.resource_id
    }
  }
}

module "private_dns_oms_opinsights" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.oms.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.oms.opinsights.azure.com"
      vnetid       = module.virtual_network.resource_id
    }
  }
}

module "private_dns_ods_opinsights" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.ods.opinsights.azure.com"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.ods.opinsights.azure.com"
      vnetid       = module.virtual_network.resource_id
    }
  }
}

module "private_dns_agentsvc" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "~> 0.2"

  domain_name         = "privatelink.agentsvc.azure-automation.net"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.agentsvc.azure-automation.net"
      vnetid       = module.virtual_network.resource_id
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
    bypass         = ["AzureServices"]
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

resource "azurerm_monitor_private_link_scope" "example" {
  name                  = "example-ampls"
  resource_group_name   = azurerm_resource_group.this.name
  ingestion_access_mode = "PrivateOnly"
  query_access_mode     = "PrivateOnly"
}

resource "azurerm_private_endpoint" "privatelinkscope" {
  location            = var.location
  name                = "pe-azuremonitor"
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.virtual_network.subnets["private_endpoints"].resource_id
  tags                = local.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-azuremonitor"
    private_connection_resource_id = azurerm_monitor_private_link_scope.example.id
    subresource_names              = ["azuremonitor"]
  }
  private_dns_zone_group {
    name = "azuremonitor-dns-zone-group"
    private_dns_zone_ids = [
      module.private_dns_storageaccount_blob.resource_id,
      module.private_dns_oms_opinsights.resource_id,
      module.private_dns_monitor.resource_id,
      module.private_dns_ods_opinsights.resource_id,
      module.private_dns_agentsvc.resource_id
    ]
  }
}

module "avm_res_log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4"

  location            = var.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
  log_analytics_workspace_internet_ingestion_enabled = false
  log_analytics_workspace_internet_query_enabled     = true
  tags                                               = local.tags
}

resource "azurerm_monitor_private_link_scoped_service" "law" {
  linked_resource_id  = module.avm_res_log_analytics_workspace.resource_id
  name                = azurerm_monitor_private_link_scope.example.name
  resource_group_name = azurerm_resource_group.this.name
  scope_name          = "privatelinkscopedservice.loganalytics"
}

module "avm_res_insights_component" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "~> 0.1"

  location                   = var.location
  name                       = module.naming.application_insights.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  workspace_id               = module.avm_res_log_analytics_workspace.resource_id
  internet_ingestion_enabled = false
  internet_query_enabled     = true
  tags                       = local.tags
}

resource "azurerm_monitor_private_link_scoped_service" "appinsights" {
  linked_resource_id  = module.avm_res_insights_component.resource_id
  name                = azurerm_monitor_private_link_scope.example.name
  resource_group_name = azurerm_resource_group.this.name
  scope_name          = "privatelinkscopedservice.appinsights"
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "azureml" {
  source = "../../"

  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location          = var.location
  name              = module.naming.machine_learning_workspace.name_unique
  resource_group_id = azurerm_resource_group.this.id
  application_insights = {
    resource_id = module.avm_res_insights_component.resource_id
  }
  container_registry = {
    resource_id = module.avm_res_containerregistry_registry.resource_id
  }
  enable_telemetry = var.enable_telemetry
  is_private       = true
  key_vault = {
    resource_id = module.avm_res_keyvault_vault.resource_id
  }
  private_endpoints = {
    api = {
      name                          = "pe-api-aml"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aml_api.resource_id]
      inherit_lock                  = false
    }
    notebooks = {
      name                          = "pe-notebooks-aml"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aml_notebooks.resource_id]
      inherit_lock                  = false
    }
  }
  storage_account = {
    resource_id = module.avm_res_storage_storageaccount.resource_id
  }
  tags = local.tags
  workspace_managed_network = {
    isolation_mode = "Disabled"
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

- [azurerm_monitor_private_link_scope.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scope) (resource)
- [azurerm_monitor_private_link_scoped_service.appinsights](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service) (resource)
- [azurerm_monitor_private_link_scoped_service.law](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_private_link_scoped_service) (resource)
- [azurerm_private_endpoint.privatelinkscope](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
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

Default: `"uksouth"`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The machine learning workspace.

## Modules

The following Modules are called:

### <a name="module_avm_res_containerregistry_registry"></a> [avm\_res\_containerregistry\_registry](#module\_avm\_res\_containerregistry\_registry)

Source: Azure/avm-res-containerregistry-registry/azurerm

Version: ~> 0.4

### <a name="module_avm_res_insights_component"></a> [avm\_res\_insights\_component](#module\_avm\_res\_insights\_component)

Source: Azure/avm-res-insights-component/azurerm

Version: ~> 0.1

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: ~> 0.9

### <a name="module_avm_res_log_analytics_workspace"></a> [avm\_res\_log\_analytics\_workspace](#module\_avm\_res\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: ~> 0.4

### <a name="module_avm_res_storage_storageaccount"></a> [avm\_res\_storage\_storageaccount](#module\_avm\_res\_storage\_storageaccount)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: ~> 0.4

### <a name="module_azureml"></a> [azureml](#module\_azureml)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_private_dns_agentsvc"></a> [private\_dns\_agentsvc](#module\_private\_dns\_agentsvc)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

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

### <a name="module_private_dns_monitor"></a> [private\_dns\_monitor](#module\_private\_dns\_monitor)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_ods_opinsights"></a> [private\_dns\_ods\_opinsights](#module\_private\_dns\_ods\_opinsights)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_oms_opinsights"></a> [private\_dns\_oms\_opinsights](#module\_private\_dns\_oms\_opinsights)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_storageaccount_blob"></a> [private\_dns\_storageaccount\_blob](#module\_private\_dns\_storageaccount\_blob)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_private_dns_storageaccount_file"></a> [private\_dns\_storageaccount\_file](#module\_private\_dns\_storageaccount\_file)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: ~> 0.2

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

### <a name="module_virtual_network"></a> [virtual\_network](#module\_virtual\_network)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: ~> 0.7

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->