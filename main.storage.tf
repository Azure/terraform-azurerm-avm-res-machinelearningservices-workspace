module "avm_res_storage_storageaccount" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.4"

  enable_telemetry              = var.enable_telemetry
  name                          = replace("sa${var.name}", "-", "")
  resource_group_name           = var.resource_group_name
  location                      = var.location
  shared_access_key_enabled     = true
  public_network_access_enabled = !var.is_private

  managed_identities = {
    system_assigned = true
  }

  private_endpoints = var.is_private && var.storage_account.private_endpoints != null ? {
    for key, value in var.storage_account.private_endpoints :
    key => {
      name                            = value.name == null ? "pe-${key}-${var.name}" : value.name
      subnet_resource_id              = value.subnet_resource_id
      subresource_name                = value.subresource_name
      private_dns_zone_resource_ids   = value.private_dns_zone_resource_ids
      private_service_connection_name = value.private_service_connection_name == null ? "psc-${key}-${var.name}" : value.private_service_connection_name
      network_interface_name          = value.network_interface_name == null ? "nic-pe-${key}-${var.name}" : value.network_interface_name
      inherit_lock                    = value.inherit_lock
    }
  } : {}

  network_rules = var.is_private ? {
    bypass         = ["Logging", "Metrics", "AzureServices"]
    default_action = "Deny"
  } : null

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

  role_assignments = (var.is_private && var.aiservices.create_service_connection) ? {
    "aiservices" = {
      role_definition_id_or_name       = "Storage Blob Data Contributor"
      principal_id                     = local.ai_services.identity.principalId
      skip_service_principal_aad_check = true
    }
  } : {}

  tags = var.storage_account.tags == null ? var.tags : var.storage_account.tags == {} ? {} : var.storage_account.tags

  count = var.storage_account.create_new ? 1 : 0
}