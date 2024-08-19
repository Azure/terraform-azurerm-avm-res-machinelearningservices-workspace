resource "azurerm_application_insights" "this" {
  count = var.application_insights.include && var.application_insights.create_new ? 1 : 0

  application_type    = "web"
  location            = var.location
  name                = "app-insights-${var.name}"
  resource_group_name = var.resource_group.name
  tags                = var.application_insights.tags
  workspace_id        = local.log_analytics_workspace_id

  lifecycle {
    ignore_changes = [
      # When the service connection to the AI Studio Hub is created, 
      # tags are added to this resource
      tags,
    ]
  }
}
