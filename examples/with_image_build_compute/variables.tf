variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "location" {
  type        = string
  default     = "East US"
  description = "The Azure region where the resources will be created."
}

variable "image_build_compute_name" {
  type        = string
  default     = "my-compute-cluster"
  description = "The name of the compute cluster to use for building environments."
}