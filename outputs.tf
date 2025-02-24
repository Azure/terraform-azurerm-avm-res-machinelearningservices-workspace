output "ai_services" {
  description = "The AI Services resource, if created."
  value = var.aiservices.create_new ? {
    id          = azapi_resource.aiservice[0].output.id
    name        = azapi_resource.aiservice[0].output.name
    endpoint    = azapi_resource.aiservice[0].output.properties.endpoint
    identity_id = try(azapi_resource.aiservice[0].output.identity.principalId, null)
  } : null
}

output "ai_services_service_connection" {
  description = "The service connection between the AIServices and the workspace, if created."
  value = var.aiservices.create_service_connection ? {
    name                           = azapi_resource.aiserviceconnection[0].output.name
    id                             = azapi_resource.aiserviceconnection[0].output.id
    is_shared                      = azapi_resource.aiserviceconnection[0].output.properties.isSharedToAll
    target                         = azapi_resource.aiserviceconnection[0].output.properties.target
    use_workspace_managed_identity = azapi_resource.aiserviceconnection[0].output.properties.useWorkspaceManagedIdentity
  } : null
}

output "private_endpoints" {
  description = "A map of the private endpoints created."
  value       = azurerm_private_endpoint.this
}

# Guidance change to prohibit output of resource as an object. This will be a breaking change next major release.
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = "The machine learning workspace."
  value       = local.aml_resource
}

output "resource_id" {
  description = "The ID of the machine learning workspace."
  value       = local.aml_resource.id
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

output "workspace_identity" {
  description = "The identity for the created workspace."
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}
