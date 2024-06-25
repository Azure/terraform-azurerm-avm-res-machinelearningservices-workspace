terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

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
  azureml_dns_zones = toset([
    "privatelink.api.azureml.ms",
    "privatelink.notebooks.azure.net",
  ])
  container_registry_endpoints = toset([
    "azurecr",
  ])
  core_services_vnet_subnets = cidrsubnets("10.0.0.0/22", 6, 2, 4, 3)
  key_vault_endpoints = toset([
    "vaultcore",
  ])
  name                                  = module.naming.machine_learning_workspace.name_unique
  shared_services_subnet_address_prefix = local.core_services_vnet_subnets[3]
  storage_account_endpoints = toset([
    "blob",
    "file",
    "queue",
    "table",
  ])
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "shared" {
  address_prefixes     = [local.shared_services_subnet_address_prefix]
  name                 = "SharedSubnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_private_dns_zone" "this" {
  for_each = local.azureml_dns_zones

  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone" "container_registry" {
  for_each = local.container_registry_endpoints

  name                = "privatelink.${each.value}.io"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone" "key_vault_dns_zones" {
  for_each = local.key_vault_endpoints

  name                = "privatelink.${each.value}.azure.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone" "storage_dns_zones" {
  for_each = local.storage_account_endpoints

  name                = "privatelink.${each.value}.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links" {
  for_each = azurerm_private_dns_zone.this

  name                  = "${each.key}_${azurerm_virtual_network.vnet.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links_container_registry" {
  for_each = azurerm_private_dns_zone.container_registry

  name                  = "${each.key}_${azurerm_virtual_network.vnet.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.container_registry[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links_keyvault" {
  for_each = azurerm_private_dns_zone.key_vault_dns_zones

  name                  = "${each.key}_${azurerm_virtual_network.vnet.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.key_vault_dns_zones[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_links_storage" {
  for_each = azurerm_private_dns_zone.storage_dns_zones

  name                  = "${each.key}_${azurerm_virtual_network.vnet.name}-link"
  private_dns_zone_name = azurerm_private_dns_zone.storage_dns_zones[each.key].name
  resource_group_name   = azurerm_resource_group.this.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

locals {
  azureml_dns_zones_map = {
    for endpoint in local.azureml_dns_zones : endpoint => [azurerm_private_dns_zone.this[endpoint].id]
  }
  container_registry_dns_zones_map = {
    for endpoint in local.container_registry_endpoints : endpoint => [azurerm_private_dns_zone.container_registry[endpoint].id]
  }
  key_vault_dnz_zones_map = {
    for endpoint in local.key_vault_endpoints : endpoint => [azurerm_private_dns_zone.key_vault_dns_zones[endpoint].id]
  }
  storage_account_dnz_zones_map = {
    for endpoint in local.storage_account_endpoints : endpoint => [azurerm_private_dns_zone.storage_dns_zones[endpoint].id]
  }
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "azureml" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location = azurerm_resource_group.this.location
  name     = local.name
  resource_group = {
    id   = azurerm_resource_group.this.id
    name = azurerm_resource_group.this.name
  }
  shared_subnet_id = azurerm_subnet.shared.id
  is_private       = true

  private_endpoints = {
    for key, value in local.azureml_dns_zones_map :
    key => {
      name                            = "pe-${key}-${local.name}"
      subnet_resource_id              = azurerm_subnet.shared.id
      subresource_name                = key
      private_dns_zone_resource_ids   = value
      private_service_connection_name = "psc-${key}-${local.name}"
      network_interface_name          = "nic-pe-${key}-${local.name}"
      inherit_lock                    = false
    }
  }

  container_registry = {
    private_dns_zone_resource_map = local.container_registry_dns_zones_map
  }

  key_vault = {
    private_dns_zone_resource_map = local.key_vault_dnz_zones_map
  }

  storage_account = {
    private_dns_zone_resource_map = local.storage_account_dnz_zones_map
  }

  enable_telemetry = var.enable_telemetry
}
