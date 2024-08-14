module "avm_res_network_virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.3"

  resource_group_name = var.resource_group.name
  name                = "vnet"
  location            = var.location

  address_space = var.vnet.address_space
  subnets       = var.vnet.subnets

  tags = var.tags

  count = var.vnet != null ? 1 : 0
}
