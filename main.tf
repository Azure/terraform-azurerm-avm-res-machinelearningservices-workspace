resource "azapi_resource" "public" {
  count = var.is_private ? 0 : 1

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = local.container_registry_id != null ? {
      publicNetworkAccess = "Enabled"
      applicationInsights = local.application_insights_id
      hbiWorkspace        = var.hbi_workspace
      friendlyName        = "AMLPublic"
      keyVault            = local.key_vault_id
      storageAccount      = local.storage_account_id
      containerRegistry   = local.container_registry_id
      } : {
      publicNetworkAccess = "Enabled"
      applicationInsights = local.application_insights_id
      hbiWorkspace        = var.hbi_workspace
      friendlyName        = "AMLPublic"
      keyVault            = local.key_vault_id
      storageAccount      = local.storage_account_id
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

resource "azapi_resource" "this" {
  count = var.is_private ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01"
  body = jsonencode({
    properties = {
      publicNetworkAccess = "Disabled"
      applicationInsights = local.application_insights_id
      containerRegistry   = local.container_registry_id
      hbiWorkspace        = var.hbi_workspace
      friendlyName        = "AMLManagedVirtualNetwork"
      keyVault            = local.key_vault_id
      imageBuildCompute   = var.image_builder_compute_cluster_name
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
      hubResourceId = local.aml_resource.id
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

# Compute cluster for image building required since the workspace is behind a vnet.
# For more details, see https://docs.microsoft.com/en-us/azure/machine-learning/tutorial-create-secure-workspace#configure-image-builds.
resource "azurerm_machine_learning_compute_cluster" "image-builder" {
  count = var.is_private ? 1 : 0

  location                      = var.location
  machine_learning_workspace_id = local.aml_resource.id
  name                          = var.image_builder_compute_cluster_name
  vm_priority                   = "LowPriority"
  vm_size                       = "Standard_DS2_v2"

  scale_settings {
    max_node_count                       = 3
    min_node_count                       = 0
    scale_down_nodes_after_idle_duration = "PT15M" # 15 minutes
  }
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
