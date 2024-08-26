module "avm_res_cognitiveservices_account" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "~> 0.1"

  resource_group_name           = var.resource_group_name
  kind                          = "CognitiveServices"
  sku_name                      = var.aiservices.analysis_services_sku
  name                          = "ai-svc-${var.name}"
  location                      = var.location
  public_network_access_enabled = var.is_private && var.kind != "Hub"
  managed_identities = {
    system_assigned = true
  }
  tags  = var.aiservices.tags == null ? var.tags : var.aiservices.tags == {} ? {} : var.aiservices.tags
  count = var.aiservices.create_new ? 1 : 0
}

data "azapi_resource" "existing_aiservices" {
  count = !var.aiservices.create_new && var.aiservices.create_service_connection ? 1 : 0

  type                   = "Microsoft.CognitiveServices/accounts@2024-04-01-preview"
  name                   = var.aiservices.name
  parent_id              = var.aiservices.resource_group_id
  response_export_values = ["*"]
}