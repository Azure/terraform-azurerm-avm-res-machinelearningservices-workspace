resource "azapi_resource" "aiservice" {
  count = var.kind == "hub" ? 1 : 0

  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  body = jsonencode({
    properties = {
      publicNetworkAccess = var.is_private ? "Disabled" : "Enabled"
      apiProperties = {
        statisticsEnabled = false
      }
    }
    sku = {
      "name" : "S0",
    }
    kind = "AIServices"
  })
  location               = var.location
  name                   = "ai-svc-${var.name}"
  parent_id              = local.resource_group_id
  response_export_values = ["*"]

  identity {
    type = "SystemAssigned"
  }
}
