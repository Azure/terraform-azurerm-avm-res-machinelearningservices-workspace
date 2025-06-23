output "ai_services" {
  description = "DEPRECATED. Will always be null."
  value       = null
}

output "ai_services_service_connection" {
  description = "DEPRECATED. Will always be null."
  value       = null
}

output "resource" {
  description = "DEPRECATED. Use `workspace` or other outputs instead. If additional fields are required, open a bug. Note: the only input value that should be output too is `name`"
  value       = null
}

output "workspace_identity" {
  description = "DEPRECATED. Use `system_assigned_mi_principal_id` instead, if the workspace was configured for system-assigned managed identity."
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}
