resource "azapi_resource" "aiservice" {
  count = var.aiservices.include && var.aiservices.create_new ? 1 : 0

  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  body = jsonencode({
    properties = {
      publicNetworkAccess = (var.is_private && var.kind != "hub") ? "Disabled" : "Enabled" # Can't have private AI Services with private AI Studio hubs
      apiProperties = {
        statisticsEnabled = false
      }
    }
    sku = {
      "name" : var.aiservices.analysis_services_sku,
    }
    kind = "AIServices"
  })
  location               = var.location
  name                   = "ai-svc-${var.name}"
  parent_id              = var.resource_group.id
  response_export_values = ["*"]

  identity {
    type = "SystemAssigned"
  }
}

data "azapi_resource" "existing_aiservices" {
  count = (var.aiservices.include == true && var.aiservices.create_new == false) ? 1 : 0

  type                   = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  name                   = var.aiservices.name
  parent_id              = var.aiservices.resource_group_id
  response_export_values = ["*"]
}
