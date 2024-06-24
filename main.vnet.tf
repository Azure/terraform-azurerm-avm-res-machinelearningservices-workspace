module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.1.0"

  resource_group_name = var.resource_group.name
  vnet_name           = local.vnet_name
  vnet_location       = var.location
  use_for_each        = true

  address_space   = var.vnet_address_space
  subnet_names    = [for s in var.subnets : s.name]
  subnet_prefixes = [for s in var.subnets : s.address_prefix]

  tags = var.tags

  count = var.associated_vnet == null ? 1 : 0
}