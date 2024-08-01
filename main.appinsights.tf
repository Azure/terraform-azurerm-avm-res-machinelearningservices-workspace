resource "azurerm_application_insights" "this" {
  application_type    = "web"
  location            = var.location
  name                = "ai-${var.name}"
  resource_group_name = var.resource_group.name
  tags                = var.tags
  workspace_id        = vars.log_analytics_workspace.resource_id
}
