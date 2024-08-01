locals {
  application_insights_id   = var.application_insights.resource_id == null ? replace(resource.application_insights.resource_id, "Microsoft.KeyVault", "Microsoft.Keyvault") : var.application_insights.resource_id
  application_insights_name = replace("ai${var.name}", "/[^a-zA-Z0-9-]/", "")
}
