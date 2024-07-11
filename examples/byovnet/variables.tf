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

variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "vnet" {
  type = object({
    resource_id = optional(string, null)
    subnets = map(object({
      name              = string
      address_prefixes  = list(string)
      service_endpoints = optional(list(string), [])
      nsg_id            = optional(string, null)
    }))
    address_space       = list(string)
    resource_group_name = optional(string, null)
  })
  default = {
    subnets = {
      "aisubnet" = {
        name             = "aisubnet"
        address_prefixes = ["10.0.1.0/24"]
      }
    }
    address_space = ["10.0.0.0/22"]
  }
  description = <<DESCRIPTION
An object describing the Virtual Network to associate with the resource. This includes the following properties:
- `resource_id` - The resource ID of the Virtual Network.
DESCRIPTION
  nullable    = false
}
