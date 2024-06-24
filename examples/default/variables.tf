variable "subnets" {
  type = map(object({
    name              = string
    address_prefix    = string
    service_endpoints = list(string)
    nsg_id            = string
  }))
  description = "A map of subnet definitions"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "The address space that is used by the Virtual Network"
}

variable "vnet_name" {
  type        = string
  description = "The name of the Virtual Network"
}

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
  default     = "uksouth"
  description = "The location for the resources."
}
