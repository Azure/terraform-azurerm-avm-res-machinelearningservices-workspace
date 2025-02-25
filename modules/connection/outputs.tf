output "name" {
  description = "The name of the created connection"
  value       = azapi_resource.connection.output.name
}

output "resource_id" {
  description = "The id of the created connection"
  value       = azapi_resource.connection.output.id
}
