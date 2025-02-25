# Guidance change to prohibit output of resource as an object. This will be a breaking change next major release.
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "resource" {
  description = <<DESCRIPTION
DEPRECATED. This value is now always `null`; please use the output `workspace` as applicable.
DESCRIPTION
  value       = null
}

output "workspace_identity" {
  description = <<DESCRIPTION
DEPRECATED. This will be removed in a future release. Please transition to using output `system_assigned_mi_principal_id`.

The identity for the created workspace.
DESCRIPTION
  value = {
    principal_id = try(local.aml_resource.identity[0].principal_id, null)
    type         = try(local.aml_resource.identity[0].type, null)
  }
}
