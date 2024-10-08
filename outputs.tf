output "application_insights" {
  description = "The ID of the application insights."
  value       = length(module.avm_res_insights_component) == 1 ? module.avm_res_insights_component[0].resource : null
}

output "container_registry" {
  description = "The container registry resource."
  value       = length(module.avm_res_containerregistry_registry) == 1 ? module.avm_res_containerregistry_registry[0].resource : null
}

output "key_vault" {
  description = "The key vault resource."
  value = length(module.avm_res_keyvault_vault) == 1 ? {
    keys_resource_ids    = module.avm_res_keyvault_vault[0].keys_resource_ids
    private_endpoints    = module.avm_res_keyvault_vault[0].private_endpoints
    resource_id          = module.avm_res_keyvault_vault[0].resource_id
    secrets_resource_ids = module.avm_res_keyvault_vault[0].secrets_resource_ids
    uri                  = module.avm_res_keyvault_vault[0].uri
  } : null
}

output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = azurerm_private_endpoint.this
}

output "resource" {
  description = "The machine learning workspace."
  value       = local.aml_resource
}

output "resource_id" {
  description = "The ID of the machine learning workspace."
  value       = local.aml_resource.id
}

output "storage_account" {
  description = "The storage account resource."
  value       = length(module.avm_res_storage_storageaccount) == 1 ? module.avm_res_storage_storageaccount[0].resource : null
}
