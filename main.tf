resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = var.location
  name                = "ai-${var.name}"
  resource_group_name = var.resource_group.name
}

resource "azapi_resource" "this" {
  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  body = jsonencode({
    properties = {
      publicNetworkAccess = var.is_private ? "Disabled" : "Enabled"
      applicationInsights = azurerm_application_insights.this.id
      containerRegistry   = var.associated_container_registry == null ? module.avm_res_containerregistry_registry[0].resource_id : var.associated_container_registry.resource_id
      hbiWorkspace        = var.hbi_workspace
      friendlyName        = "AMLManagedVirtualNetwork"
      keyVault            = var.associated_key_vault == null ? module.avm_res_keyvault_vault[0].resource_id : var.associated_key_vault.resource_id
      managedNetwork = {
        isolationMode = "AllowInternetOutbound"
        status = {
          sparkReady = true
          status     = "Active"
        }
      }
      storageAccount = var.associated_storage_account == null ? module.avm_res_storage_storageaccount[0].resource_id : var.associated_storage_account.resource_id
    }
    kind = var.kind
  })
  location  = var.location
  name      = "aml-${var.name}"
  parent_id = var.resource_group.id
  tags = {
    vnettype = "managed"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = var.resource_group.name
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
