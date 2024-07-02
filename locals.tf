locals {
  application_insights_id = replace(azurerm_application_insights.this.id, "Microsoft.Insights", "Microsoft.insights")
  key_vault_id            = var.key_vault.resource_id == null ? replace(module.avm_res_keyvault_vault[0].resource_id, "Microsoft.KeyVault", "Microsoft.Keyvault") : var.key_vault.resource_id
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
}
