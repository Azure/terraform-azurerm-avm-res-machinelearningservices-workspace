resource "azapi_resource" "this" {
  count = var.kind == "Default" ? 1 : 0

  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.current.id
  type      = "Microsoft.MachineLearningServices/workspaces@2025-07-01-preview"
  body = {
    properties = {
      publicNetworkAccess      = local.enable_public_network_access ? "Enabled" : "Disabled"
      applicationInsights      = local.application_insights_id
      hbiWorkspace             = var.hbi_workspace
      keyVault                 = local.key_vault_id
      storageAccount           = var.storage_account.resource_id
      containerRegistry        = try(var.container_registry.resource_id, null)
      description              = var.workspace_description
      friendlyName             = coalesce(var.workspace_friendly_name, (local.enable_public_network_access ? "Public AML" : "Private AML"))
      systemDatastoresAuthMode = var.storage_access_type
      managedNetwork = {
        isolationMode = var.workspace_managed_network.isolation_mode
        status = {
          sparkReady = var.workspace_managed_network.spark_ready
        }
        outboundRules = local.outbound_rules
        firewallSku   = var.workspace_managed_network.firewall_sku
      }
      ipAllowlist       = var.ip_allowlist
      imageBuildCompute = var.image_build_compute
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
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_casing  = true
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    var.resource_group_name # since this is the value that determines if parent_id changes, require create/destroy if it changes
  ]
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.managed_identities

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  lifecycle {
    ignore_changes = [
      tags,      # tags are occasionally added by Azure
      parent_id, # because this comes from data, the azapi provider doesn't know it ahead of time which leads to destroy/recreate instead of update
    ]
  }
}

resource "azapi_resource" "hub" {
  count = var.kind == "Hub" ? 1 : 0

  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.current.id
  type      = "Microsoft.MachineLearningServices/workspaces@2025-07-01-preview"
  body = {
    properties = {
      provisionNetworkNow      = var.provision_network_now_enabled
      publicNetworkAccess      = local.enable_public_network_access ? "Enabled" : "Disabled"
      applicationInsights      = local.application_insights_id
      hbiWorkspace             = var.hbi_workspace
      keyVault                 = local.key_vault_id
      storageAccount           = var.storage_account.resource_id
      containerRegistry        = try(var.container_registry.resource_id, null)
      description              = var.workspace_description
      friendlyName             = coalesce(var.workspace_friendly_name, (local.enable_public_network_access ? "Public Hub" : "Private Hub"))
      systemDatastoresAuthMode = var.storage_access_type
      managedNetwork = {
        isolationMode = var.workspace_managed_network.isolation_mode
        status = {
          sparkReady = var.workspace_managed_network.spark_ready
        }
        outboundRules = local.outbound_rules
        firewallSku   = var.workspace_managed_network.firewall_sku
      }
      ipAllowlist       = var.ip_allowlist
      imageBuildCompute = var.image_build_compute
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
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  ignore_casing  = true
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    var.resource_group_name, # since this is the value that determines if parent_id changes, require create/destroy if it changes
    var.provision_network_now_enabled
  ]
  tags           = var.tags
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.managed_identities

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  lifecycle {
    ignore_changes = [
      tags,     # When the service connections for CognitiveServices are created, tags are added to this resource
      parent_id # because this comes from data, the azapi provider doesn't know it ahead of time which leads to destroy/recreate instead of update
    ]
  }
}

# Azure AI Project
resource "azapi_resource" "project" {
  count = var.kind == "Project" ? 1 : 0

  location  = var.location
  name      = var.name
  parent_id = data.azurerm_resource_group.current.id
  type      = "Microsoft.MachineLearningServices/workspaces@2025-07-01-preview"
  body = {
    properties = {
      description                     = var.workspace_description
      friendlyName                    = coalesce(var.workspace_friendly_name, "AI Project")
      hubResourceId                   = var.azure_ai_hub.resource_id
      provisionNetworkNow             = var.provision_network_now_enabled
      allowPublicAccessWhenBehindVnet = var.public_access_when_behind_vnet_enabled
      hbiWorkspace                    = var.hbi_workspace
    }
    kind = var.kind
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_external_values = [
    var.provision_network_now_enabled
  ]
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "identity" {
    for_each = local.managed_identities

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }

  lifecycle {
    ignore_changes = [
      tags,     # When the service connections for CognitiveServices are created, tags are added to this resource
      parent_id # because this comes from data, the azapi provider doesn't know it ahead of time which leads to destroy/recreate instead of update
    ]
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
