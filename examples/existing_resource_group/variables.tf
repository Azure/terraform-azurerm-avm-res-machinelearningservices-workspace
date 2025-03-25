variable "resource_group_name" {
  type        = string
  description = "The name of an existing resource group."

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "`var.resource_group_name` is required."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "force_purge_on_delete" {
  type        = bool
  default     = false
  description = "Whether to force purge when the workspace is destroyed. When `false`, a soft delete is performed. When `true`, the workspace is fully deleted."
}
