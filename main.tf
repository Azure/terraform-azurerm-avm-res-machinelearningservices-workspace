resource "azapi_resource" "this" {
  count = var.kind == "Default" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      publicNetworkAccess = var.is_private ? "Disabled" : "Enabled"
      applicationInsights = local.application_insights_id
      hbiWorkspace        = var.hbi_workspace
      keyVault            = local.key_vault_id
      storageAccount      = local.storage_account_id
      containerRegistry   = local.container_registry_id
      friendlyName        = var.is_private ? "AMLManagedVirtualNetwork" : "AMLPublic"
      managedNetwork = {
        isolationMode = var.workspace_managed_network.isolation_mode
        status = {
          sparkReady = var.workspace_managed_network.spark_ready
        }
      }
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

resource "azapi_resource" "hub" {
  count = var.kind == "Hub" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      publicNetworkAccess = var.is_private ? "Disabled" : "Enabled"
      applicationInsights = local.application_insights_id
      hbiWorkspace        = var.hbi_workspace
      keyVault            = local.key_vault_id
      storageAccount      = local.storage_account_id
      containerRegistry   = local.container_registry_id
      friendlyName        = var.is_private ? "HubManagedVirtualNetwork" : "PublicHub"
      managedNetwork = {
        isolationMode = var.workspace_managed_network.isolation_mode
        status = {
          sparkReady = var.workspace_managed_network.spark_ready
        }
      }
    }
    kind = var.kind
  })
  location  = var.location
  name      = "hub-${var.name}"
  parent_id = var.resource_group.id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      # When the service connections for CognitiveServices are created, 
      # tags are added to this resource
      tags,
    ]
  }
}

# Azure AI Project
resource "azapi_resource" "project" {
  count = var.kind == "Project" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      description   = "Azure AI PROJECT"
      friendlyName  = "AIStudioProject"
      hubResourceId = var.aistudio_hub_id
    }
    kind = var.kind
  })
  location  = var.location
  name      = "project-${var.name}"
  parent_id = var.resource_group.id

  identity {
    type = "SystemAssigned"
  }
}

# Azure AI Project for Hub
resource "azapi_resource" "hubproject" {
  count = var.kind == "Hub" && var.project_for_hub.create_new ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      description   = "Azure AI PROJECT"
      friendlyName  = var.project_for_hub.project_name
      hubResourceId = local.aml_resource.id
    }
    kind = "Project"
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
  count = var.aiservices.include ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-04-01"
  body = jsonencode({
    properties = {
      category      = "AIServices",
      target        = jsondecode(local.ai_services).properties.endpoint,
      authType      = "AAD",
      isSharedToAll = true,
      metadata = {
        ApiType    = "Azure",
        ResourceId = local.ai_services_id
      }
    }
  })
  name                   = "aiserviceconnection${var.name}"
  parent_id              = local.aml_resource.id
  response_export_values = ["*"]
}

# Azure Machine Learning Compute Instance
resource "azapi_resource" "computeinstance" {
  count = var.create_compute_instance ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces/computes@2024-04-01"
  body = jsonencode({
    properties = {
      computeType = "ComputeInstance"
      properties = {
        enableNodePublicIp = false
        vmSize             = "STANDARD_DS2_V2"
      }
    }
  })
  location  = local.aml_resource.location
  name      = "ci-${var.name}"
  parent_id = local.aml_resource.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = local.aml_resource.id
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
