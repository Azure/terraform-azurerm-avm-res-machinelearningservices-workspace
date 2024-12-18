module "avm_res_log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "~> 0.4.2"

  enable_telemetry    = var.enable_telemetry
  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "la-${var.name}"

  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }

  log_analytics_workspace_internet_ingestion_enabled = (var.is_private == false)
  log_analytics_workspace_internet_query_enabled     = (var.is_private == false)

  tags  = var.application_insights.log_analytics_workspace.tags == null ? var.tags : var.application_insights.log_analytics_workspace.tags == {} ? {} : var.application_insights.log_analytics_workspace.tags
  count = var.application_insights.log_analytics_workspace.create_new ? 1 : 0
}
