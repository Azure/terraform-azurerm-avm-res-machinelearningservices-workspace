resource "azurerm_application_insights" "this" {
  count = var.application_insights.create_new && var.application_insights.resource_id == null ? 1 : 0

  application_type    = "web"
  location            = var.location
  name                = "app-insights-${var.name}"
  resource_group_name = var.resource_group.name
  tags                = var.tags
  workspace_id        = local.log_analytics_workspace_id
}
