data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "current" {
  name = var.resource_group_name
}

data "azurerm_key_vault_key" "cmk" {
  count = var.customer_managed_key == null ? 0 : 1

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}

# tflint-ignore: terraform_comment_syntax
data "azurerm_user_assigned_identity" "cmk" {
  count = var.customer_managed_key == null || var.customer_managed_key.user_assigned_identity == null ? 0 : 1

  name = try(
    provider::azapi::parse_resource_id("Microsoft.ManagedIdentity/userAssignedIdentities", var.customer_managed_key.user_assigned_identity.resource_id),
  "")
  resource_group_name = var.resource_group_name
}