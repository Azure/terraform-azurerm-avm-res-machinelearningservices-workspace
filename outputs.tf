output "ai_services" {
  description = "The AI Services resource, if created."
  value = var.aiservices.create_new ? {
    id          = jsondecode(azapi_resource.aiservice[0].output).id
    name        = jsondecode(azapi_resource.aiservice[0].output).name
    endpoint    = jsondecode(azapi_resource.aiservice[0].output).properties.endpoint
    identity_id = try(jsondecode(azapi_resource.aiservice[0].output).identity.principalId, null)
  } : null
}

output "ai_services_service_connection" {
  description = "The service connection between the AIServices and the workspace, if created."
  value = var.aiservices.create_service_connection ? {
    name                           = jsondecode(azapi_resource.aiserviceconnection[0].output).name
    id                             = jsondecode(azapi_resource.aiserviceconnection[0].output).id
    is_shared                      = jsondecode(azapi_resource.aiserviceconnection[0].output).properties.isSharedToAll
    target                         = jsondecode(azapi_resource.aiserviceconnection[0].output).properties.target
    use_workspace_managed_identity = jsondecode(azapi_resource.aiserviceconnection[0].output).properties.useWorkspaceManagedIdentity
  } : null
}

output "application_insights" {
  description = "The application insights resource, if created."
  value = length(module.avm_res_insights_component) == 1 ? {
    resource_id         = module.avm_res_insights_component[0].resource_id
    name                = module.avm_res_insights_component[0].name
    app_id              = module.avm_res_insights_component[0].app_id
    connection_string   = module.avm_res_insights_component[0].connection_string
    instrumentation_key = module.avm_res_insights_component[0].instrumentation_key
  } : null
}

output "container_registry" {
  description = "The container registry resource, if created."
  value = length(module.avm_res_containerregistry_registry) == 1 ? {
    resource_id                         = module.avm_res_containerregistry_registry[0].resource_id
    name                                = module.avm_res_containerregistry_registry[0].name
    system_assigned_managed_identity_id = module.avm_res_containerregistry_registry[0].system_assigned_mi_principal_id
  } : null
}

output "key_vault" {
  description = "The key vault resource, if created."
  value = length(module.avm_res_keyvault_vault) == 1 ? {
    keys_resource_ids    = module.avm_res_keyvault_vault[0].keys_resource_ids
    private_endpoints    = module.avm_res_keyvault_vault[0].private_endpoints
    resource_id          = module.avm_res_keyvault_vault[0].resource_id
    secrets_resource_ids = module.avm_res_keyvault_vault[0].secrets_resource_ids
    uri                  = module.avm_res_keyvault_vault[0].uri
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

output "storage_account" {
  description = "The storage account resource, if created."
  value = length(module.avm_res_storage_storageaccount) == 1 ? {
    resource_id = module.avm_res_storage_storageaccount[0].resource_id
    name        = module.avm_res_storage_storageaccount[0].name
    containers  = module.avm_res_storage_storageaccount[0].containers
    fqdn        = module.avm_res_storage_storageaccount[0].fqdn
    queues      = module.avm_res_storage_storageaccount[0].queues
    tables      = module.avm_res_storage_storageaccount[0].tables
    shares      = module.avm_res_storage_storageaccount[0].shares
  } : null
}

output "workspace" {
  description = "The machine learning workspace created."
  value = {
    name                    = local.aml_resource.name
    container_registry_id   = try(jsondecode(local.aml_resource.body).properties.containerRegistry, null)
    storage_account_id      = try(jsondecode(local.aml_resource.body).properties.storageAccount, null)
    key_vault_id            = try(jsondecode(local.aml_resource.body).properties.keyVault, null)
    application_insights_id = try(jsondecode(local.aml_resource.body).properties.applicationInsights, null)
  }
}

output "workspace_identity" {
  description = "The identity for the created workspace."
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}
