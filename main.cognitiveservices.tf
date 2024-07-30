resource "azapi_resource" "aiservice" {
  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  count = var.kind == "hub" ? 1 : 0

  identity {
    type = "SystemAssigned"
  }

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
  location  = var.location
  name      = local.cognitive_services_name
  parent_id = var.resource_group.id
  response_export_values = ["*"]
}
