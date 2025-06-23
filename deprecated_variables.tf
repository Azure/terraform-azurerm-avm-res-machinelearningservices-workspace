variable "ai_studio_hub_id" {
  type        = string
  default     = null
  description = "DEPRECATED. Use variable `azure_ai_hub`."
}

variable "aiservices" {
  type = object({
    create_new                = optional(bool, false)
    analysis_services_sku     = optional(string, "S0")
    name                      = optional(string, null)
    resource_group_id         = optional(string, null)
    tags                      = optional(map(string), null)
    create_service_connection = optional(bool, false)
  })
  default     = null
  description = <<DESCRIPTION
An object describing the AI Services resource to create or reference. This includes the following properties:
- `create_new`: (Optional) A flag indicating if a new resource must be created. If set to 'false', both `name` and `resource_group_id` must be provided.
- `analysis_services_sku`: (Optional) When creating a new resource, this specifies the SKU of the Azure Analysis Services server. Possible values are: `D1`, `B1`, `B2`, `S0`, `S1`, `S2`, `S4`, `S8`, `S9`. Availability may be impacted by region; see https://learn.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region
- `name`: (Optional) If providing an existing resource, the name of the AI Services to reference
- `resource_group_id`: (Optional) If providing an existing resource, the id of the resource group where the AI Services resource resides
- `tags`: (Optional) Tags for the AI Services resource.
- `create_service_connection`: (Optional) Whether or not to create a service connection between the Workspace resource and AI Services resource.
DESCRIPTION
}

variable "create_compute_instance" {
  type        = bool
  default     = false
  description = "DEPRECATED: No compute instance created if true."
}

variable "is_private" {
  type        = bool
  default     = null
  description = "DEPRECATED. Please use `var.public_network_access_enabled`."
}

variable "outbound_rules" {
  type = map(object({
    resource_id         = string
    sub_resource_target = string
  }))
  default     = {}
  description = <<DESCRIPTION
  DEPRECATED. Please use `var.workspace_managed_network.outbound_rules.private_endpoint` instead. It will be removed completely in a later release.
  
  A map of private endpoints outbound rules for the managed network.

  - `resource_id` - The resource id for the corresponding private endpoint.
  - `sub_resource_target` - The sub_resource_target is target for the private endpoint. e.g. account for Openai, searchService for Azure Ai Search

  DESCRIPTION
}
