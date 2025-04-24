resource "azapi_resource" "this" {
  count = var.kind == "Default" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  body = {
    properties = {
      publicNetworkAccess      = var.is_private ? "Disabled" : "Enabled"
      applicationInsights      = local.application_insights_id
      hbiWorkspace             = var.hbi_workspace
      keyVault                 = local.key_vault_id
      storageAccount           = var.storage_account.resource_id
      containerRegistry        = try(var.container_registry.resource_id, null)
      description              = var.workspace_description
      friendlyName             = coalesce(var.workspace_friendly_name, (var.is_private ? "AMLManagedVirtualNetwork" : "AMLPublic"))
      systemDatastoresAuthMode = var.storage_access_type
      networkAcls = var.network_acls != null ? {
        defaultAction = var.network_acls.default_action
        ipRules       = var.network_acls.ip_rules
      } : null
      managedNetwork = {
        isolationMode = var.workspace_managed_network.isolation_mode
        status = {
          sparkReady = var.workspace_managed_network.spark_ready
        }
        outboundRules = local.outbound_rules
        firewallSku   = var.workspace_managed_network.firewall_sku
      }
      ipAllowlist = var.ip_allowlist
      encryption = var.customer_managed_key != null ? {
        status = "Enabled" # the other option is Disabled
        identity = var.customer_managed_key.user_assigned_identity != null ? {
          userAssignedIdentity = var.customer_managed_key.user_assigned_identity.resource_id
        } : null
        keyVaultProperties = {
          keyVaultArmId = var.customer_managed_key.key_vault_resource_id
          keyIdentifier = var.customer_managed_key.key_version == null ? data.azurerm_key_vault_key.cmk[0].id : "${data.azurerm_key_vault_key.cmk[0].versionless_id}/${var.customer_managed_key.key_version}"
        }
      } : null
      primaryUserAssignedIdentity = var.managed_identities.system_assigned == true ? "" : var.primary_user_assigned_identity.resource_id
    }
    kind = var.kind
  }
  location  = var.location
  name      = var.name
  parent_id = local.parent_resource_id
  tags      = var.tags

  dynamic "identity" {
    for_each = local.managed_identities

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  lifecycle {
    ignore_changes = [
      tags, # tags are occasionally added by Azure
    ]
  }
}

resource "azapi_resource" "hub" {
  count = var.kind == "Hub" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  body = {
    properties = {
      publicNetworkAccess      = var.is_private ? "Disabled" : "Enabled"
      applicationInsights      = local.application_insights_id
      hbiWorkspace             = var.hbi_workspace
      keyVault                 = local.key_vault_id
      storageAccount           = var.storage_account.resource_id
      containerRegistry        = try(var.container_registry.resource_id, null)
      description              = var.workspace_description
      friendlyName             = coalesce(var.workspace_friendly_name, (var.is_private ? "HubManagedVirtualNetwork" : "PublicHub"))
      systemDatastoresAuthMode = var.storage_access_type
      managedNetwork = {
        isolationMode = var.workspace_managed_network.isolation_mode
        status = {
          sparkReady = var.workspace_managed_network.spark_ready
        }
        outboundRules = local.outbound_rules
        firewallSku   = var.workspace_managed_network.firewall_sku
      }
      ipAllowlist = var.ip_allowlist
      encryption = var.customer_managed_key != null ? {
        status = "Enabled" # the other option is Disabled
        identity = var.customer_managed_key.user_assigned_identity != null ? {
          userAssignedIdentity = var.customer_managed_key.user_assigned_identity.resource_id
        } : null
        keyVaultProperties = {
          keyVaultArmId = var.customer_managed_key.key_vault_resource_id
          keyIdentifier = var.customer_managed_key.key_version == null ? data.azurerm_key_vault_key.cmk[0].id : "${data.azurerm_key_vault_key.cmk[0].versionless_id}/${var.customer_managed_key.key_version}"
        }
      } : null
      primaryUserAssignedIdentity = var.managed_identities.system_assigned == true ? "" : var.primary_user_assigned_identity.resource_id
    }
    kind = var.kind
  }
  location  = var.location
  name      = var.name
  parent_id = local.parent_resource_id
  tags      = var.tags

  dynamic "identity" {
    for_each = local.managed_identities

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  lifecycle {
    ignore_changes = [
      tags, # When the service connections for CognitiveServices are created, tags are added to this resource
    ]
  }
}

# Azure AI Project
resource "azapi_resource" "project" {
  count = var.kind == "Project" ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces@2024-10-01-preview"
  body = {
    properties = {
      description   = var.workspace_description
      friendlyName  = coalesce(var.workspace_friendly_name, "AI Project")
      hubResourceId = var.ai_studio_hub_id
    }
    kind = var.kind
  }
  location  = var.location
  name      = "aihubproject-${var.name}"
  parent_id = data.azurerm_resource_group.current.id

  dynamic "identity" {
    for_each = local.managed_identities

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
}

# AzAPI AI Services Connection
resource "azapi_resource" "aiserviceconnection" {
  count = var.aiservices.create_service_connection ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-10-01-preview"
  body = {
    properties = {
      category      = "AIServices"
      target        = local.ai_services.properties.endpoint
      authType      = "AAD"
      isSharedToAll = true
      metadata = {
        ApiType    = "Azure",
        ResourceId = local.ai_services_id
      }
    }
  }
  name                   = "aiserviceconnection${var.name}"
  parent_id              = local.aml_resource.id
  response_export_values = ["*"]
}

# Azure Machine Learning Compute Instance
resource "azapi_resource" "computeinstance" {
  count = var.create_compute_instance ? 1 : 0

  type = "Microsoft.MachineLearningServices/workspaces/computes@2024-10-01-preview"
  body = {
    properties = {
      computeLocation  = local.aml_resource.location
      computeType      = "ComputeInstance"
      disableLocalAuth = true
      properties = {
        enableNodePublicIp = false
        vmSize             = "STANDARD_DS2_V2"
      }
    }
  }
  location               = local.aml_resource.location
  name                   = "ci-${var.name}"
  parent_id              = local.aml_resource.id
  response_export_values = ["*"]

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
  scope                                  = local.aml_resource.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}
