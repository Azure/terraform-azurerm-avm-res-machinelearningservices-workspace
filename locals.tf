locals {
  ai_services                = var.aiservices.create_new ? azapi_resource.aiservice[0].output : var.aiservices.create_service_connection ? data.azapi_resource.existing_aiservices[0].output : null
  ai_services_id             = var.aiservices.create_new ? azapi_resource.aiservice[0].id : var.aiservices.create_service_connection ? data.azapi_resource.existing_aiservices[0].output.id : null
  aml_resource               = var.kind == "Default" ? azapi_resource.this[0] : var.kind == "Hub" ? azapi_resource.hub[0] : azapi_resource.project[0]
  application_insights_id    = var.application_insights.create_new || var.application_insights.resource_id != null ? replace(var.application_insights.create_new ? module.avm_res_insights_component[0].resource_id : var.application_insights.resource_id, "Microsoft.Insights", "Microsoft.insights") : null
  container_registry_id      = var.container_registry.create_new ? module.avm_res_containerregistry_registry[0].resource_id : var.container_registry.resource_id
  # key_vault_id               = replace(var.key_vault.create_new ? module.avm_res_keyvault_vault[0].resource_id : var.key_vault.resource_id, "Microsoft.KeyVault", "Microsoft.Keyvault")
  key_vault_id = var.key_vault.use_microsoft_managed_key_vault? null : replace(
  var.key_vault.create_new ? module.avm_res_keyvault_vault[0].resource_id : var.key_vault.resource_id,
  "Microsoft.KeyVault",
  "Microsoft.Keyvault"
)
  log_analytics_workspace_id = var.application_insights.log_analytics_workspace.create_new ? module.avm_res_log_analytics_workspace[0].resource_id : var.application_insights.log_analytics_workspace.resource_id
  # application_insights_id = replace(azurerm_application_insights.this.id, "Microsoft.Insights", "Microsoft.insights")
  managed_identities = {
    this = {
      type                       = var.managed_identities.system_assigned && length(var.managed_identities.user_assigned_resource_ids) > 0 ? "SystemAssigned, UserAssigned" : length(var.managed_identities.user_assigned_resource_ids) > 0 ? "UserAssigned" : "SystemAssigned"
      user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
    }
  }
  # merge outbound rules into a single map
  outbound_rules = merge(
    {
      for key, rule in var.workspace_managed_network.outbound_rules.fqdn :
      key => {
        type        = "FQDN"
        destination = rule.destination
      }
    },
    {
      for key, rule in var.outbound_rules :
      key => {
        type = "PrivateEndpoint"
        destination = {
          serviceResourceId = rule.resource_id
          subresourceTarget = rule.sub_resource_target
          sparkEnabled      = false
          sparkStatus       = "Inactive"
        }
      }
    },
    {
      for key, rule in var.workspace_managed_network.outbound_rules.private_endpoint :
      key => {
        type = "PrivateEndpoint"
        destination = {
          serviceResourceId = rule.resource_id
          sparkEnabled      = rule.spark_enabled
          subresourceTarget = rule.sub_resource_target
        }
      }
    },
    {
      for key, rule in var.workspace_managed_network.outbound_rules.service_tag :
      key => {
        type = "ServiceTag"
        destination = {
          action          = rule.action
          addressPrefixes = rule.address_prefixes
          portRanges      = rule.port_ranges
          protocol        = rule.protocol
          serviceTag      = rule.service_tag
        }
      }
  })
  # Private endpoint application security group associations.
  # We merge the nested maps from private endpoints and application security group associations into a single map.
  private_endpoint_application_security_group_associations = { for assoc in flatten([
    for pe_k, pe_v in var.private_endpoints : [
      for asg_k, asg_v in pe_v.application_security_group_associations : {
        asg_key         = asg_k
        pe_key          = pe_k
        asg_resource_id = asg_v
      }
    ]
  ]) : "${assoc.pe_key}-${assoc.asg_key}" => assoc }
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  # Resources that may or may not be created from this module
  storage_account_id = var.storage_account.create_new ? module.avm_res_storage_storageaccount[0].resource_id : var.storage_account.resource_id
}

