module "avm_res_insights_component" {
  source  = "Azure/avm-res-insights-component/azurerm"
  version = "~> 0.1"

  location            = var.location
  resource_group_name = var.resource_group_name
  name                = "app-insights-${var.name}"
  workspace_id        = local.log_analytics_workspace_id
  tags                = var.application_insights.tags == null ? var.tags : var.application_insights.tags == {} ? {} : var.application_insights.tags

  count = var.application_insights.create_new ? 1 : 0
}