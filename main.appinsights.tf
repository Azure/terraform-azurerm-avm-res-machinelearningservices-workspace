resource "azurerm_application_insights" "this" {
  count = var.application_insights.create_new ? 1 : 0

  application_type    = "web"
  location            = var.location
  name                = "app-insights-${var.name}"
  resource_group_name = var.resource_group_name
  tags                = var.application_insights.tags == null ? var.tags : var.application_insights.tags == {} ? {} : var.application_insights.tags
  workspace_id        = local.log_analytics_workspace_id
}
