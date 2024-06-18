output "private_endpoints" {
  description = <<DESCRIPTION
  A map of the private endpoints created.
  DESCRIPTION
  value       = azurerm_private_endpoint.this
}

output "resource" {
  description = "The machine learning workspace."
  value       = azurerm_machine_learning_workspace.this
}

output "resource_id" {
  description = "The ID of the machine learning workspace."
  value       = azurerm_machine_learning_workspace.this.id
}
