module "avm_res_storage_storageaccount" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.1"

  enable_telemetry              = var.enable_telemetry
  name                          = local.storage_account_name
  resource_group_name           = var.resource_group.name
  location                      = var.location
  shared_access_key_enabled     = true
  public_network_access_enabled = var.is_private ? false : true

  managed_identities = {
    system_assigned = true
  }

  private_endpoints = var.is_private ? {
    for key, value in var.storage_account.private_endpoints :
    key => {
      name                            = value.name == null ? "pe-${key}-${var.name}" : value.name
      subnet_resource_id              = value.subnet_resource_id == null ? data.azurerm_subnet.shared.id : value.subnet_resource_id
      subresource_name                = value.subresource_name
      private_dns_zone_resource_ids   = value.private_dns_zone_resource_ids
      private_service_connection_name = value.private_service_connection_name == null ? "psc-${key}-${var.name}" : value.private_service_connection_name
      network_interface_name          = value.network_interface_name == null ? "nic-pe-${key}-${var.name}" : value.network_interface_name
      inherit_lock                    = value.inherit_lock
    }
  } : {}

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = var.is_private ? "Deny" : "Allow"
  }

  count = var.storage_account.resource_id == null ? 1 : 0
}
