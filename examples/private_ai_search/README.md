<!-- BEGIN_TF_DOCS -->
# Private Workspace with AI Search

This provisions Azure AI Search Service and deploys a private Azure Machine Learning Workspace with an outbound rule allowing connection to the Search Service over private endpoint.

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
  version = "~> 0.4"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = var.tags
}

module "virtual_network" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.7.0"
  resource_group_name = azurerm_resource_group.this.name
  subnets = {
    private_endpoints = {
      name                              = "private_endpoints"
      address_prefixes                  = ["192.168.0.0/24"]
      private_endpoint_network_policies = "Disabled"
      service_endpoints                 = null
    }
  }
  address_space = ["192.168.0.0/24"]
  location      = var.location
  name          = module.naming.virtual_network.name_unique
  tags          = var.tags
}

module "private_dns_aml_api" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.api.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_aml_notebooks" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.notebooks.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.notebooks.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_keyvault_vault" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.notebooks.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_storageaccount_blob" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.blob.core.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_storageaccount_file" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.file.core.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_containerregistry_registry" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.azurecr.io"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_aisearch" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.2.1"
  domain_name         = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.search.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = var.tags
  enable_telemetry = var.enable_telemetry
}

module "aisearch" {
  source                        = "Azure/avm-res-search-searchservice/azurerm"
  version                       = "0.1.3"
  location                      = var.location
  name                          = module.naming.search_service.name_unique
  resource_group_name           = azurerm_resource_group.this.name
  public_network_access_enabled = false
  enable_telemetry              = var.enable_telemetry

  private_endpoints = {
    primary = {
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aisearch.resource_id]
      tags                          = var.tags
    }
  }

  local_authentication_enabled = false
  managed_identities = {
    system_assigned = true
  }
  tags = var.tags
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "azureml" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = var.location
  name                = module.naming.machine_learning_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  is_private          = true
  workspace_managed_network = {
    isolation_mode = "AllowOnlyApprovedOutbound"
    outbound_rules = {
      private_endpoint = {
        aisearch = {
          resource_id         = module.aisearch.resource_id
          sub_resource_target = "searchService"
        }
      }
    }
  }
  private_endpoints = {
    primary = {
      name                          = "pe-aml-workspace"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aml_api.resource_id, module.private_dns_aml_notebooks.resource_id]
      inherit_lock                  = false
    }
  }

  storage_account = {
    create_new = true
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
  }

  container_registry = {
    create_new = true
    private_endpoints = {
      registry = {
        name                          = "pe-containerregistry-regsitry"
        subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
        private_dns_zone_resource_ids = [module.private_dns_containerregistry_registry.resource_id]
        inherit_lock                  = false
      }
    }
  }

  key_vault = {
    create_new = true
    private_endpoints = {
      vault = {
        name                          = "pe-keyvault-vault"
        subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
        private_dns_zone_resource_ids = [module.private_dns_keyvault_vault.resource_id]
        inherit_lock                  = false
      }
    }
  }

  application_insights = {
    create_new = true
    log_analytics_workspace = {
      create_new = true
    }
  }

  enable_telemetry = var.enable_telemetry
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.116.0, < 4.0.0)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

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

Default: `"eastus2"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

## Outputs

The following outputs are exported:

### <a name="output_resource"></a> [resource](#output\_resource)

Description: Relevant properties of the machine learning workspace and supporting resources.

## Modules

The following Modules are called:

### <a name="module_aisearch"></a> [aisearch](#module\_aisearch)

Source: Azure/avm-res-search-searchservice/azurerm

Version: 0.1.3

### <a name="module_azureml"></a> [azureml](#module\_azureml)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.4

### <a name="module_private_dns_aisearch"></a> [private\_dns\_aisearch](#module\_private\_dns\_aisearch)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_private_dns_aml_api"></a> [private\_dns\_aml\_api](#module\_private\_dns\_aml\_api)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_private_dns_aml_notebooks"></a> [private\_dns\_aml\_notebooks](#module\_private\_dns\_aml\_notebooks)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_private_dns_containerregistry_registry"></a> [private\_dns\_containerregistry\_registry](#module\_private\_dns\_containerregistry\_registry)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_private_dns_keyvault_vault"></a> [private\_dns\_keyvault\_vault](#module\_private\_dns\_keyvault\_vault)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_private_dns_storageaccount_blob"></a> [private\_dns\_storageaccount\_blob](#module\_private\_dns\_storageaccount\_blob)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_private_dns_storageaccount_file"></a> [private\_dns\_storageaccount\_file](#module\_private\_dns\_storageaccount\_file)

Source: Azure/avm-res-network-privatednszone/azurerm

Version: 0.2.1

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

### <a name="module_virtual_network"></a> [virtual\_network](#module\_virtual\_network)

Source: Azure/avm-res-network-virtualnetwork/azurerm

Version: 0.7.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->