terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

resource "random_string" "name" {
  length  = 5
  numeric = false
  special = false
  upper   = false
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  unique-length = 5
  unique-seed   = random_string.name.id
}

data "azurerm_client_config" "current" {}

locals {
  tags = {
    scenario = "Private AML with AI Search"
  }
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

resource "azurerm_role_assignment" "connection_approver" {
  principal_id       = data.azurerm_client_config.current.object_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/b556d68e-0be0-4f35-a333-ad7ee1ce17ea" #  Azure AI Enterprise Network Connection Approver
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
  version = "0.3.5"

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
  version = "0.3.5"

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
  version = "0.3.5"

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
  version = "0.3.5"

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
  version = "0.3.5"

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
  version = "0.3.5"

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

module "private_dns_aisearch" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.3.5"

  domain_name         = "privatelink.search.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
  virtual_network_links = {
    dnslink = {
      vnetlinkname = "privatelink.search.windows.net"
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
  # for idempotency
  share_properties = {
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
  shared_access_key_enabled = true
  tags                      = local.tags
}

module "aisearch" {
  source  = "Azure/avm-res-search-searchservice/azurerm"
  version = "0.1.5"

  location                     = var.location
  name                         = module.naming.search_service.name_unique
  resource_group_name          = azurerm_resource_group.this.name
  enable_telemetry             = var.enable_telemetry
  local_authentication_enabled = false
  managed_identities = {
    system_assigned = true
  }
  private_endpoints = {
    primary = {
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aisearch.resource_id]
      tags                          = local.tags
    }
  }
  public_network_access_enabled = false
  tags                          = local.tags
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
  log_analytics_workspace_internet_ingestion_enabled = true
  log_analytics_workspace_internet_query_enabled     = true
  tags                                               = local.tags
}

module "avm_res_insights_component" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "~> 0.1"

  location                   = var.location
  name                       = module.naming.application_insights.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  workspace_id               = module.avm_res_log_analytics_workspace.resource_id
  internet_ingestion_enabled = true
  internet_query_enabled     = true
  tags                       = local.tags
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
  application_insights = {
    resource_id = module.avm_res_insights_component.resource_id
  }
  container_registry = {
    resource_id = module.avm_res_containerregistry_registry.resource_id
  }
  enable_telemetry = var.enable_telemetry
  key_vault = {
    resource_id = module.avm_res_keyvault_vault.resource_id
  }
  private_endpoints = {
    primary = {
      name                          = "pe-aml-workspace"
      subnet_resource_id            = module.virtual_network.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_aml_api.resource_id, module.private_dns_aml_notebooks.resource_id]
      inherit_lock                  = false
    }
  }
  public_network_access_enabled = true
  storage_account = {
    resource_id = module.avm_res_storage_storageaccount.resource_id
  }
  tags = local.tags
  workspace_managed_network = {
    isolation_mode = "AllowInternetOutbound"
    outbound_rules = {
      private_endpoint = {
        aisearch = {
          resource_id         = module.aisearch.resource_id
          sub_resource_target = "searchService"
        }
      }
    }
  }
}

resource "azapi_resource" "search_connection" {
  name      = "srch${random_string.name.id}"
  parent_id = module.azureml.resource_id
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-01-01-preview"
  body = {
    properties = {
      category      = "CognitiveSearch"
      target        = "https://${module.aisearch.resource.name}.search.windows.net"
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure",
        ResourceId = module.aisearch.resource_id
      }
    }
  }
}
