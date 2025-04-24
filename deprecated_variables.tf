variable "create_compute_instance" {
  type        = bool
  default     = false
  description = "Specifies whether a compute instance should be created for the workspace to provision the managed vnet. **Due to the complexity of compute instances and to prevent setting precedent that compute provisioning will be included in this module, this will be deprecated in a future release."
}

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

variable "storage_access_type" {
  type        = string
  default     = "identity"
  description = <<DESCRIPTION
The authentication mode used for accessing the system datastores of the workspace. Valid options include 'accessKey' and 'identity'. **This will be deprecated once the version of ARM used with the azapi provider is updated from 2024-07-01-preview as it was removed from the schema.
DESCRIPTION

  validation {
    condition     = contains(["accesskey", "identity"], var.storage_access_type)
    error_message = "Valid options for storage access auth mode are 'accesskey' or 'identity'."
  }
}
