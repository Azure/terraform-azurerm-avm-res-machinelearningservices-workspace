locals {
  first_subnet_key = keys(var.vnet.subnets)[0]
  vnet_name        = length(var.vnet.resource_id) == 0 ? replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "") : regex("[^/]+$", var.vnet.resource_id)
}
