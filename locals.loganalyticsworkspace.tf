locals {
  log_analytics_workspace_id   = var.log_analytics_workspace.resource_id == null ? replace(module.avm_res_log_analytics_workspace.resource_id, "Microsoft.KeyVault", "Microsoft.Keyvault") : var.log_analytics_workspace.resource_id
  log_analytics_workspace_name = replace("la${var.name}", "/[^a-zA-Z0-9-]/", "")
}
