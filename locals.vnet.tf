locals {
  vnet_name = var.vnet == null ? replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "") : can(length(var.vnet.resource_id)) && length(var.vnet.resource_id) == 0 ? replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "") : regex("(?<=/)[^/]+$", var.vnet.resource_id)
}