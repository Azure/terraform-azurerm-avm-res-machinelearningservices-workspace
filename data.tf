data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "current" {
  name = var.resource_group_name
}

data "azurerm_key_vault_key" "this" {
  count = var.customer_managed_key == null ? 0 : 1

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}

locals {
  cmk_user = var.customer_managed_key == null ? "" : provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.customer_managed_key.user_assigned_identity.resource_id)
}

data "azurerm_user_assigned_identity" "cmk" {
  count = var.customer_managed_key == null ? 0 : 1

  name                = local.cmk_user.name
  resource_group_name = var.resource_group_name
}