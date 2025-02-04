module "avm_res_keyvault_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "~> 0.9"

  tenant_id           = data.azurerm_client_config.current.tenant_id
  enable_telemetry    = var.enable_telemetry
  name                = "kv-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  network_acls = var.is_private ? {
    bypass         = "AzureServices"
    default_action = "Deny"
  } : null

  public_network_access_enabled = !var.is_private

  private_endpoints = var.is_private && var.key_vault.private_endpoints != null ? {
    for key, value in var.key_vault.private_endpoints :
    key => {
      name                            = value.name == null ? "pe-${key}-${var.name}" : value.name
      subnet_resource_id              = value.subnet_resource_id
      private_dns_zone_resource_ids   = value.private_dns_zone_resource_ids
      private_service_connection_name = value.private_service_connection_name == null ? "psc-${key}-${var.name}" : value.private_service_connection_name
      network_interface_name          = value.network_interface_name == null ? "nic-pe-${key}-${var.name}" : value.network_interface_name
      inherit_lock                    = value.inherit_lock
    }
  } : {}
  tags = var.key_vault.tags == null ? var.tags : var.key_vault.tags == {} ? {} : var.key_vault.tags


  count = var.key_vault.use_microsoft_managed_key_vault ? 0 : (var.key_vault.create_new ? 1 : 0)
}
