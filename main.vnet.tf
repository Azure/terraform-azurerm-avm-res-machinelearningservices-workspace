module "avm-res-network-virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.3"

  resource_group_name = var.resource_group.name
  name                = local.vnet_name
  location            = var.location

  address_space = var.vnet_address_space
  subnets       = var.subnets

  tags = var.tags

  count = var.associated_vnet == null ? 1 : 0
}