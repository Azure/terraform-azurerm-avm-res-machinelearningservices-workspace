module "avm_res_containerregistry_registry" {
  source = "Azure/avm-res-containerregistry-registry/azurerm"

  version = "~> 0.4"

  name                          = replace("acr${var.name}", "-", "")
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = !var.is_private
  zone_redundancy_enabled       = var.container_registry.zone_redundant

  private_endpoints = var.is_private && var.container_registry.private_endpoints != null ? {
    for key, value in var.container_registry.private_endpoints :
    key => {
      name                            = value.name == null ? "pe-${key}-${var.name}" : value.name
      subnet_resource_id              = value.subnet_resource_id
      private_dns_zone_resource_ids   = value.private_dns_zone_resource_ids
      private_service_connection_name = value.private_service_connection_name == null ? "psc-${key}-${var.name}" : value.private_service_connection_name
      network_interface_name          = value.network_interface_name == null ? "nic-pe-${key}-${var.name}" : value.network_interface_name
      inherit_lock                    = value.inherit_lock
    }
  } : {}

  tags = var.container_registry.tags == null ? var.tags : var.container_registry.tags == {} ? {} : var.container_registry.tags

  count = var.container_registry.create_new ? 1 : 0
}
