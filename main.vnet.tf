module "avm_res_network_virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.3"

  resource_group_name = var.resource_group.name
  name                = local.vnet_name
  location            = var.location

  address_space = var.vnet.address_space
  subnets       = var.vnet.subnets

  tags = var.tags

  count = var.vnet.create_new ? 1 : 0
}

data "azurerm_subnet" "shared" {
  name                 = var.vnet.subnets[local.first_subnet_key].name
  resource_group_name  = var.vnet.resource_group_name == null ? var.resource_group.name : var.vnet.resource_group_name
  virtual_network_name = var.vnet.resource_id == null ? module.avm_res_network_virtualnetwork[0].name : local.vnet_name

  depends_on = [module.avm_res_network_virtualnetwork]
}
