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
