locals {
  vnet_name = var.vnet == null || length(var.vnet.resource_id) > 0 ? regex("(?<=/)[^/]+$", var.vnet.resource_id) : replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "")
}