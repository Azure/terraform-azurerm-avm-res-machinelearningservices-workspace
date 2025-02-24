data "azurerm_resource_group" "current" {
  name = var.resource_group_name
}

data "azurerm_key_vault_key" "cmk" {
  count = var.customer_managed_key == null ? 0 : 1

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}