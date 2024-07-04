resource "azapi_resource" "ai_services" {
  type = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  body = jsonencode({
    properties = {
      publicNetworkAccess = var.is_private ? "Disabled" : "Enabled"
    }
    sku = {
      "name" : "S0",
    }
    kind = "AIServices"
  })
  location  = var.location
  name      = local.cognitive_services_name
  parent_id = var.resource_group.id
}
