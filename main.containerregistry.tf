module "avm_res_containerregistry_registry" {
  source = "Azure/avm-res-containerregistry-registry/azurerm"

  version = "~> 0.1"

  name                          = local.container_registry_name
  location                      = var.location
  resource_group_name           = var.resource_group.name
  public_network_access_enabled = var.is_private ? false : true

  private_endpoints = var.is_private ? {
    for key, value in var.container_registry.private_dns_zone_resource_map :
    key => {
      name                            = "pe-${key}-${var.name}"
      subnet_resource_id              = var.shared_subnet_id
      subresource_name                = key
      private_dns_zone_resource_ids   = value
      private_service_connection_name = "psc-${key}-${var.name}"
      network_interface_name          = "nic-pe-${key}-${var.name}"
      inherit_lock                    = false
    }
  } : {}

  count = var.associated_container_registry == null ? 1 : 0
}
