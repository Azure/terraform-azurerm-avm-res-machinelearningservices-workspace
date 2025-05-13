data "azapi_resource" "rg" {
  type        = "Microsoft.Resources/resourceGroups@2024-11-01"
  resource_id = var.resource_group_id
}

data "azurerm_key_vault_key" "cmk" {
  count = var.customer_managed_key == null ? 0 : 1

  key_vault_id = var.customer_managed_key.key_vault_resource_id
  name         = var.customer_managed_key.key_name
}
