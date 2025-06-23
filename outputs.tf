output "private_endpoints" {
  description = "A map of the private endpoints created."
  value       = azurerm_private_endpoint.this
}

output "resource_id" {
  description = "The ID of the machine learning workspace."
  value       = local.aml_resource.id
}

output "system_assigned_mi_principal_id" {
  description = "The system-assigned managed identity for the created workspace, if applicable."
  value       = try(local.aml_resource.identity[0].principal_id, null)
}

output "workspace" {
  description = "The machine learning workspace created."
  value = {
    name                    = local.aml_resource.name
    container_registry_id   = try(local.aml_resource.body.properties.containerRegistry, null)
    storage_account_id      = try(local.aml_resource.body.properties.storageAccount, null)
    key_vault_id            = try(local.aml_resource.body.properties.keyVault, null)
    application_insights_id = try(local.aml_resource.body.properties.applicationInsights, null)
  }
}
