locals {
  vnet_name = var.vnet == null ? replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "") : var.vnet.resource_id == null ? replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "") : regex("(?<=/)[^/]+$", var.vnet.resource_id)
}