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
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "~> 0.7"
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
  tags          = local.tags
}

module "private_dns_aml_api" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.2"
  domain_name         = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.api.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_aml_notebooks" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.2"
  domain_name         = "privatelink.notebooks.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.notebooks.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_keyvault_vault" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.2"
  domain_name         = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.notebooks.azureml.ms"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_storageaccount_blob" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.2"
  domain_name         = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.blob.core.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_storageaccount_file" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.2"
  domain_name         = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.file.core.windows.net"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "private_dns_containerregistry_registry" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "~> 0.2"
  domain_name         = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.this.name
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.azurecr.io"
      vnetid       = module.virtual_network.resource.id
    }
  }
  tags             = local.tags
  enable_telemetry = var.enable_telemetry
}

module "avm_res_containerregistry_registry" {
  source = "Azure/avm-res-containerregistry-registry/azurerm"

  version = "~> 0.4"

  name                          = replace(module.naming.container_registry.name_unique, "-", "")
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  public_network_access_enabled = false
  zone_redundancy_enabled       = false

  private_endpoints = {
    registry = {
      name                          = "pe-containerregistry-regsitry"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_containerregistry_registry.resource_id]
      inherit_lock                  = false
    }
  }

  tags = local.tags
}

module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  public_network_access_enabled = false

  private_endpoints = {
    vault = {
      name                          = "pe-keyvault-vault"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_keyvault_vault.resource_id]
      inherit_lock                  = false
    }
  }

  tags = local.tags
}

module "avm_res_storage_storageaccount" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  enable_telemetry              = var.enable_telemetry
  name                          = replace(module.naming.storage_account.name_unique, "-", "")
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  shared_access_key_enabled     = true
  public_network_access_enabled = false

  managed_identities = {
    system_assigned = true
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

  network_rules = {
    bypass         = ["Logging", "Metrics", "AzureServices"]
    default_action = "Deny"
  }

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

  tags = local.tags
}

module "ai_services" {
  source                             = "Azure/avm-res-cognitiveservices-account/azurerm"
  version                            = "0.6.0"
  resource_group_name                = azurerm_resource_group.this.name
  kind                               = "AIServices"
  name                               = module.naming.cognitive_account.name_unique
  location                           = var.location
  enable_telemetry                   = var.enable_telemetry
  sku_name                           = "S0"
  public_network_access_enabled      = true # required for AI Foundry
  local_auth_enabled                 = true
  outbound_network_access_restricted = false
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
  location                = azurerm_resource_group.this.location
  name                    = local.name
  resource_group_name     = azurerm_resource_group.this.name
  is_private              = true
  kind                    = "Hub"
  workspace_friendly_name = "Private AI Studio Hub"
  workspace_managed_network = {
    isolation_mode = "AllowOnlyApprovedOutbound"
  }

  storage_account = {
    resource_id = module.avm_res_storage_storageaccount.resource_id
  }

  key_vault = {
    resource_id = module.avm_res_keyvault_vault.resource_id
  }

  container_registry = {
    resource_id = module.avm_res_containerregistry_registry.resource_id
  }

  aiservices = {
    resource_group_id         = azurerm_resource_group.this.id
    name                      = module.ai_services.name
    create_service_connection = true
  }

  private_endpoints = {
    hub = {
      name                          = "pe-aistudio-hub"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aml_api.resource_id, module.private_dns_aml_notebooks.resource_id]
      inherit_lock                  = false
    }
  }

  enable_telemetry = var.enable_telemetry
}
