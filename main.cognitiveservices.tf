resource "azapi_resource" "aiservice" {
  count = var.aiservices.create_new ? 1 : 0

  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  body = {
    properties = {
      publicNetworkAccess = (var.is_private && var.kind != "Hub") ? "Disabled" : "Enabled" # Can't have private AI Services with private AI Studio hubs
      apiProperties = {
        statisticsEnabled = false
      }
    }
    sku = {
      "name" : var.aiservices.analysis_services_sku,
    }
    kind = "AIServices"
  }
  location               = var.location
  name                   = "ai-svc-${var.name}"
  parent_id              = local.resource_group_id
  response_export_values = ["*"]
  tags                   = var.aiservices.tags == null ? var.tags : var.aiservices.tags == {} ? {} : var.aiservices.tags

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      # When the service connection to the AI Studio Hub is created,
      # tags are added to this resource
      tags,
    ]
  }
}

data "azapi_resource" "existing_aiservices" {
  count = !var.aiservices.create_new && var.aiservices.create_service_connection ? 1 : 0

  type                   = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  name                   = var.aiservices.name
  parent_id              = var.aiservices.resource_group_id
  response_export_values = ["*"]
}
