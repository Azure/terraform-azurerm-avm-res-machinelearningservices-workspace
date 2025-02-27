output "connections" {
  description = "The connections created between the workspace/hub/project and other services"
  value       = [for _, conn in module.connections : { resource_id = conn.resource_id, name = conn.name }]
}

output "name" {
  description = "The name of the resource."
  value       = local.aml_resource.name
}

output "private_endpoints" {
  description = "A map of the private endpoints created."
  value       = azurerm_private_endpoint.this
}

output "resource_id" {
  description = "The ID of the resource."
  value       = local.aml_resource.id
}

output "system_assigned_mi_principal_id" {
  description = "The identity for the resource."
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}

output "workspace" {
  description = "The created resource."
  value = {
    name                    = local.aml_resource.name
    container_registry_id   = try(local.aml_resource.body.properties.containerRegistry, null)
    storage_account_id      = try(local.aml_resource.body.properties.storageAccount, null)
    key_vault_id            = try(local.aml_resource.body.properties.keyVault, null)
    application_insights_id = try(local.aml_resource.body.properties.applicationInsights, null)
  }
}
