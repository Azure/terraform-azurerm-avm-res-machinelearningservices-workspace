variable "outbound_rules" {
  type = map(object({
    resource_id         = string
    sub_resource_target = string
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of private endpoints outbound rules for the managed network. **This will be deprecated in favor of the `var.workspace_managed_network.outbound_rules` in a future release. Until then, the final outbound rules of type 'PrivateEndpoint' will be a combination of this variable's value and that of `workspace_managed_network.outbound_rules.private_endpoint`.

  - `resource_id` - The resource id for the corresponding private endpoint.
  - `sub_resource_target` - The sub_resource_target is target for the private endpoint. e.g. account for Openai, searchService for Azure Ai Search
  
  DESCRIPTION
}
