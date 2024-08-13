# resource "azurerm_log_analytics_workspace" "main" {
#   name                = "ai-${var.name}"
#   location            = var.location
#   resource_group_name = var.resource_group.name

#   count = var.log_analytics_workspace.create_new ? 1 : 0
# }

module "avm_res_log_analytics_workspace" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.3.3"

  enable_telemetry    = var.enable_telemetry
  location            = var.location
  resource_group_name = var.resource_group.name
  name                = "la-${var.name}"

  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }

  count = var.log_analytics_workspace.create_new && var.log_analytics_workspace.resource_id == null ? 1 : 0
}
