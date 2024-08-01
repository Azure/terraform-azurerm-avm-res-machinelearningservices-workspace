locals {
  log_analytics_workspace_id   = var.log_analytics_workspace.create_new ? module.avm_res_log_analytics_workspace[0].resource_id : var.log_analytics_workspace.resource_id
  log_analytics_workspace_name = replace("la${var.name}", "/[^a-zA-Z0-9-]/", "")
}
