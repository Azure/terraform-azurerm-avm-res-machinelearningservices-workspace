module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.7"

  tenant_id                     = data.azurerm_client_config.current.tenant_id
  enable_telemetry              = var.enable_telemetry
  name                          = local.key_vault_name
  resource_group_name           = var.resource_group.name
  location                      = var.location
  public_network_access_enabled = var.is_private ? false : true

  private_endpoints = var.is_private ? {
    for key, value in var.key_vault.private_endpoints :
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



  count = var.key_vault.resource_id == null ? 1 : 0
}
