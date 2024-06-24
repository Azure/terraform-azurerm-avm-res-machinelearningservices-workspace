locals {
  vnet_name = replace("vn${var.name}", "/[^a-zA-Z0-9-]/", "")
}