module "avm_res_containerregistry_registry" {
  source = "Azure/avm-res-containerregistry-registry/azurerm"

  version = "~> 0.1"

  name                          = local.container_registry_name
  location                      = var.location
  resource_group_name           = var.resource_group.name
  public_network_access_enabled = var.is_private ? false : true

  private_endpoints = var.is_private ? {
    for key, value in var.container_registry.private_endpoints :
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

  tags = var.tags

  count = var.container_registry.create_new ? 1 : 0
}
