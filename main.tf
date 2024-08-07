
resource "azapi_resource" "this" {
  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      publicNetworkAccess = var.is_private ? "Disabled" : "Enabled"
      applicationInsights = local.application_insights_id
      containerRegistry   = local.container_registry_id
      hbiWorkspace        = var.hbi_workspace
      friendlyName        = "AMLManagedVirtualNetwork"
      keyVault            = local.key_vault_id
      managedNetwork = {
        isolationMode = "AllowInternetOutbound"
        status = {
          sparkReady = true
          status     = "Active"
        }
      }
      storageAccount = local.storage_account_id
    }
    kind = var.kind
  })
  location  = var.location
  name      = "aml-${var.name}"
  parent_id = var.resource_group.id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# Azure AI Project
resource "azapi_resource" "aiproject" {
  count = var.kind == "hub" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      description   = "Azure AI PROJECT"
      friendlyName  = "AI Project"
      hubResourceId = azapi_resource.this.id
    }
    kind = "project"
  })
  location  = var.location
  name      = "aihubproject-${var.name}"
  parent_id = var.resource_group.id

  identity {
    type = "SystemAssigned"
  }
}

# AzAPI AI Services Connection
resource "azapi_resource" "aiserviceconnection" {
  count = var.kind == "hub" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01"
  body = jsonencode({
    properties = {
      category      = "AIServices",
      target        = jsondecode(azapi_resource.aiservice[count.index].output).properties.endpoint,
      authType      = "AAD",
      isSharedToAll = true,
      metadata = {
        ApiType    = "Azure",
        ResourceId = azapi_resource.aiservice[count.index].id
      }
    }
  })
  name                   = "aiserviceconnection${var.name}"
  parent_id              = azapi_resource.this.id
  response_export_values = ["*"]
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
