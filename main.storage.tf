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
    for key, value in var.storage_account.private_dns_zone_resource_map :
    key => {
      name                            = "pe-${key}-${var.name}"
      subnet_resource_id              = var.shared_subnet_id
      subresource_name                = key
      private_dns_zone_resource_ids   = value
      private_service_connection_name = "psc-${key}-${var.name}"
      network_interface_name          = "nic-pe-${key}-${var.name}"
      inherit_lock                    = false
    }
  } : null

  count = var.associated_storage_account == null ? 1 : 0
}
