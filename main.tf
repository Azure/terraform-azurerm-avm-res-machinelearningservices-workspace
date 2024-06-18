resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = var.location
  name                = "ai-${var.name}"
  resource_group_name = var.resource_group_name
}

resource "azurerm_machine_learning_workspace" "this" {
  application_insights_id = azurerm_application_insights.this.id
  key_vault_id            = var.associated_key_vault == null ? module.avm_res_keyvault_vault[0].resource_id : var.associated_key_vault.resource_id
  location                = var.location
  name                    = var.name
  resource_group_name     = var.resource_group_name
  storage_account_id      = var.associated_storage_account == null ? module.avm_res_storage_storageaccount[0].resource_id : var.associated_storage_account.resource_id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_machine_learning_workspace.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = var.resource_group_name
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
