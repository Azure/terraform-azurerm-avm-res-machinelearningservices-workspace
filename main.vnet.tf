module "avm_res_network_virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.3"

  resource_group_name = var.resource_group.name
  name                = local.vnet_name
  location            = var.location

  address_space = var.vnet.address_space
  subnets       = var.vnet.subnets

  tags = var.tags

  count = var.vnet == null ? 0 : can(length(var.vnet.resource_id)) && length(var.vnet.resource_id) > 0 ? 1 : 0

}

data "azurerm_subnet" "shared" {
  name                 = var.vnet == null ? module.avm_res_network_virtualnetwork.subnet_names[0] : var.vnet.subnets[0].name
  resource_group_name  = var.vnet == null ? var.resource_group.name : can(length(var.vnet.resource_id)) && length(var.vnet.resource_id) == 0 ? var.resource_group.name : var.vnet.resource_group_name
  virtual_network_name = local.vnet_name
}