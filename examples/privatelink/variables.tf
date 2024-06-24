variable "subnets" {
  type = map(object({
    name              = string
    address_prefixes  = list(string)
    service_endpoints = list(string)
    nsg_id            = string
  }))
  description = "A map of subnet definitions"
}

variable "associated_vnet" {
  type = object({
    resource_id = string
  })
  default     = null
  description = <<DESCRIPTION
An object describing the Virtual Network to associate with the resource. This includes the following properties:
- `resource_id` - The resource ID of the Virtual Network.
DESCRIPTION
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

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "The address space that is used by the Virtual Network"
}
