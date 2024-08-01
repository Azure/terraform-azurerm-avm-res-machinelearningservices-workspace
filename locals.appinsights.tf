locals {
  application_insights_id   = var.application_insights.create_new ? azurerm_application_insights.this[0].id : var.application_insights.resource_id
  application_insights_name = replace("ai${var.name}", "/[^a-zA-Z0-9-]/", "")
}
