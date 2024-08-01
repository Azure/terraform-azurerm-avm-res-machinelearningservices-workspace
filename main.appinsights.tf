resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = var.location
  name                = "ai-${var.name}"
  resource_group_name = var.resource_group.name
  tags                = var.tags
  workspace_id        = local.log_analytics_workspace_id

  count = var.application_insights.create_new ? 1 : 0

}
