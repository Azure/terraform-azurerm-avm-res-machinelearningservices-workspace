variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("^[0-9A-Za-z-]{5,}$", var.name))
    error_message = "`name` must only contain -, a-z, A-Z, or 0-9."
  }
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "ai_studio_hub_id" {
  type        = string
  default     = null
  description = "The AI Studio Hub ID for which to create a Project"

  validation {
    condition     = var.kind != "Project" || var.ai_studio_hub_id != null
    error_message = "The Hub ID is required when `var.kind` equals 'Project'"
  }
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
  default = {
    create_new = false
  }
  description = <<DESCRIPTION
An object describing the AI Services resource to create or reference. This includes the following properties:
- `create_new`: (Optional) A flag indicating if a new resource must be created. If set to 'false', both `name` and `resource_group_id` must be provided.
- `analysis_services_sku`: (Optional) When creating a new resource, this specifies the SKU of the Azure Analysis Services server. Possible values are: `D1`, `B1`, `B2`, `S0`, `S1`, `S2`, `S4`, `S8`, `S9`. Availability may be impacted by region; see https://learn.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region
- `name`: (Optional) If providing an existing resource, the name of the AI Services to reference
- `resource_group_id`: (Optional) If providing an existing resource, the id of the resource group where the AI Services resource resides
- `tags`: (Optional) Tags for the AI Services resource.
- `create_service_connection`: (Optional) Whether or not to create a service connection between the Workspace resource and AI Services resource.
DESCRIPTION

  validation {
    condition     = !(var.aiservices.create_new && var.aiservices.resource_group_id != null && var.aiservices.name != null)
    error_message = "When creating new AI Services resource, `name` and `resource_group_id` must be null."
  }
}

variable "application_insights" {
  type = object({
    resource_id = optional(string, null)
    create_new  = bool
    tags        = optional(map(string), null)
    log_analytics_workspace = optional(object({
      resource_id = optional(string, null)
      create_new  = bool
      tags        = optional(map(string), null)
      }), {
      create_new = false
    })
  })
  default = {
    create_new = false
  }
  description = <<DESCRIPTION
An object describing the Application Insights resource to create or use for monitoring inference endpoints. This includes the following properties:
- `resource_id` - (Optional) The resource ID of an existing Application Insights resource.
- `create_new` - A flag indicating if a new resource must be created.
- `tags` - (Optional) Tags for a new Application Insights resource.
- `log_analytics_workspace` - An object describing the Log Analytics Workspace for the Application Insights resource
  - `resource_id` - The resource ID of an existing Log Analytics Workspace.
  - `create_new` - A flag indicating if a new workspace must be created.
  - `tags` - (Optional) Tags for the Log Analytics Workspace resource.
DESCRIPTION

  validation {
    condition     = !(var.application_insights.create_new && var.application_insights.resource_id != null) && (var.application_insights.create_new == false || (var.application_insights.create_new == true && (var.application_insights.log_analytics_workspace.resource_id != null || var.application_insights.log_analytics_workspace.create_new)))
    error_message = "If creating a new Application Insights resource, `resource_id` must be null and either `log_analytics_workspace.create_new` must be true or `log_analytics_workspace.resource_id` must not be null"
  }
}

variable "container_registry" {
  type = object({
    resource_id = optional(string, null)
    create_new  = bool
    private_endpoints = optional(map(object({
      name                            = optional(string, null)
      subnet_resource_id              = optional(string, null)
      private_dns_zone_resource_ids   = optional(set(string), [])
      private_service_connection_name = optional(string, null)
      network_interface_name          = optional(string, null)
      inherit_lock                    = optional(bool, false)
    })), {})
    tags           = optional(map(string), null)
    zone_redundant = optional(bool, false)
  })
  default = {
    create_new = false
  }
  description = <<DESCRIPTION
An object describing the Container Registry. This includes the following properties:
- `resource_id` - The resource ID of an existing Container Registry, if desired.
- `create_new` -  A flag indicating if a new resource must be created.
- `private_endpoints` - A map of private endpoints to create on a newly created Container Registry. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `inherit_lock` - (Optional) If set to true, the private endpoint will inherit the lock from the parent resource. Defaults to false.
- `tags` - (Optional) Tags for new Container Registry resource.
- `zone_redundant` - (Optional) A flag indicating whether to enable zone redundancy.

> Note: This module does not support creating a container registry encrypted with customer-managed keys. Please create one beforehand and supply the `resource_id`.
DESCRIPTION

  validation {
    condition     = (var.kind == "Project") || !(var.container_registry.create_new && var.container_registry.resource_id != null)
    error_message = "For Project workspaces: no registry is ever created or associated with the new Project. For Hub and Default workspaces, when creating a new registry, `resource_id` must be null"
  }
}

# required AVM interfaces
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION  
}

# required AVM interface
variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
  A map of diagnostic settings to create on the Azure Machine Learning Workspace. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  
  - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
  - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
  - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
  - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
  - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
  - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
  - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
  - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
  - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
  - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
  DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

# required AVM interface
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "hbi_workspace" {
  type        = bool
  default     = false
  description = "Specifies if the resource is a High Business Impact (HBI) workspace."
}

variable "is_private" {
  type        = bool
  default     = false
  description = "Specifies if every provisioned resource should be private and inaccessible from the Internet."
}

variable use_managed_key_vault {
  # only applicable to AI Hub, that is when kind is Hub
  type        = bool
  default     = false
  description = "Specifies if the module should use a managed key vault."
}
variable "key_vault" {
  type = object({
    resource_id = optional(string, null)
    create_new  = bool
    private_endpoints = optional(map(object({
      name                            = optional(string, null)
      subnet_resource_id              = optional(string, null)
      private_dns_zone_resource_ids   = optional(set(string), [])
      private_service_connection_name = optional(string, null)
      network_interface_name          = optional(string, null)
      inherit_lock                    = optional(bool, false)
    })), {})
    tags = optional(map(string), null)
  })
  default = {
    # only applicable to AI Hub, that is when kind is Hub, check the use_managed_key_vault variable
    create_new = true
    # create_new = var.use_managed_key_vault
  }
  description = <<DESCRIPTION
An object describing the Key Vault to create the private endpoint connection to. This includes the following properties:
- `resource_id` - The resource ID of an existing Key Vault.
- `create_new` -  A flag indicating if a new resource must be created.
- `private_endpoints` - A map of private endpoints to create on a newly created Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `inherit_lock` - (Optional) If set to true, the private endpoint will inherit the lock from the parent resource. Defaults to false.
- `tags` - (Optional) Tags for the Key Vault resource.
DESCRIPTION

  validation {
    condition     = !(var.key_vault.create_new && var.key_vault.resource_id != null)
    error_message = "When creating a new Key Vault, `resource_id` must be null."
  }
}

variable "kind" {
  type        = string
  default     = "Default"
  description = <<DESCRIPTION
The kind of the resource. This is used to determine the type of the resource. If not specified, the resource will be created as a standard resource.
Possible values are:
- `Default` - The resource will be created as a standard Azure Machine Learning resource.
- `Hub` - The resource will be created as an AI Hub resource.
- `Project` - The resource will be created as an AI Studio Project resource.
DESCRIPTION

  validation {
    condition     = contains(["Default", "Hub", "Project"], var.kind)
    error_message = "The only valid values are 'Default', 'Hub' or 'Project'"
  }
}

# required AVM interface
variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# required AVM interface
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "primary_user_assigned_identity" {
  type = object({
    resource_id = optional(string, null)
  })
  default     = {}
  description = <<DESCRIPTION
The resource id of the primary user-assigned managed identity for the workspace.
DESCRIPTION
  nullable    = false

  validation {
    condition     = var.primary_user_assigned_identity.resource_id != null || (var.managed_identities.system_assigned == true || length(var.managed_identities.user_assigned_resource_ids) == 0)
    error_message = "Required if `var.managed_identities.user_assigned_resource_ids` has one or more values. If `var.managed_identities.system_assigned` is true, this variable is ignored."
  }
}

# required AVM interface
variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.
DESCRIPTION
  nullable    = false
}

# required AVM interface
variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

variable "storage_account" {
  type = object({
    resource_id = optional(string, null)
    create_new  = bool
    private_endpoints = optional(map(object({
      name                            = optional(string, null)
      subnet_resource_id              = optional(string, null)
      subresource_name                = string
      private_dns_zone_resource_ids   = optional(set(string), [])
      private_service_connection_name = optional(string, null)
      network_interface_name          = optional(string, null)
      inherit_lock                    = optional(bool, false)
    })), {})
    tags = optional(map(string), null)
  })
  default = {
    create_new = true
  }
  description = <<DESCRIPTION
An object describing the Storage Account. This includes the following properties:
- `create_new` - Required. If 'false', `resource_id` is required.
- `resource_id` - The resource ID of an existing Storage Account.
- `private_endpoints` - A map of private endpoints to create on a newly created Storage Account. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `inherit_lock` - (Optional) If set to true, the private endpoint will inherit the lock from the parent resource. Defaults to false.
- `tags` - (Optional) Tags for the Storage Account resource.

> Note: This module does not support creating a storage account encrypted with customer-managed keys. Please create one beforehand and supply the `resource_id`.
DESCRIPTION

  validation {
    condition     = (var.kind == "Project") || (var.storage_account.create_new == false && var.storage_account.resource_id != null) || (var.storage_account.create_new == true && var.storage_account.resource_id == null)
    error_message = "Either `create_new` must be set to true and `resource_id` must be set to null or `create_new` must be set to false and `resource_id` must be set to a valid resource ID."
  }
}

# required AVM interface
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "workspace_description" {
  type        = string
  default     = ""
  description = "The description of this workspace."
}

variable "workspace_friendly_name" {
  type        = string
  default     = "Workspace"
  description = "The friendly name for this workspace. This value in mutable."
}

variable "workspace_managed_network" {
  type = object({
    isolation_mode = string
    spark_ready    = optional(bool, true)
    outbound_rules = optional(object({
      fqdn = optional(map(object({
        destination = string
      })), {})
      private_endpoint = optional(map(object({
        resource_id         = string
        sub_resource_target = string
        spark_enabled       = optional(bool, false)
      })), {})
      service_tag = optional(map(object({
        action           = string
        service_tag      = string
        address_prefixes = optional(list(string), null)
        protocol         = string
        port_ranges      = string
      })), {})
    }), {})
  })
  default = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }
  description = <<DESCRIPTION
Specifies properties of the workspace's managed virtual network.

- `isolation_mode`: While is possible to update the workspace to enable network isolation (going from 'Disabled' to 'AllowInternetOutbound' or 'AllowOnlyApprovedOutbound'), it is not possible to disable it on a workspace with it enabled.
  - 'Disabled': Inbound and outbound traffic is unrestricted _or_ BYO VNet to protect resources.
  - 'AllowInternetOutbound': Allow all internet outbound traffic.
  - 'AllowOnlyApprovedOutbound': Outbound traffic is allowed by specifying service tags.
- `spark_ready` determines whether spark jobs will be run on the network. This value can be updated in the future.
- `outbound_rules`: 
  - `fqdn`: A map of FQDN rules. Only valid when `isolation_mode` is 'AllowOnlyApprovedOutbound'. **The inclusion of FQDN rules requires Azure Firewall to be deployed and used and cost will increase accordingly.
    - `destination`: The allowed host name. Required. Examples: '*.anaconda.com' to install packages, 'pypi.org' to list dependencies, '*.tensorflow.org' for use with TensorFlow examples
  - `private_endpoint`: A map of Private Endpoint rules.
    - `resource_id`: The id of the resource with the private endpoint to enable the workspace to communicate with. Required.
    - `sub_resource_target`: The specific target endpoint for the resource. Some Azure resources have only 1 option, while others will expose multiple. Required.
    - `spark_enabled`: Whether to the endpoint should be Spark-enabled. This is primarily set 'true' if, and only if, `spark_ready` is true.
  - `service_tag`: A map of Service Tag rules. Only valid when `isolation_mode` is 'AllowOnlyApprovedOutbound'.
    - `action`: The networking rule to apply. Available options are 'Allow' or 'Deny'.
    - `service_tag`: The target service tag.
    - `address_prefixes`: Optional collection of address prefixes. If provided, `service_tag` will be ignored.
    - `protocol`: The allowed protocol(s). Valid options dependent on Service Tag. 
    - `port_ranges`: The allow port(s) / port ranges. Valid options dependent on Service Tag.
DESCRIPTION

  validation {
    condition     = contains(["AllowOnlyApprovedOutbound", "AllowInternetOutbound", "Disabled"], var.workspace_managed_network.isolation_mode)
    error_message = "The only valid options for `isolation_mode` are 'Disabled', 'AllowInternetOutbound' or 'AllowOnlyApprovedOutbound'."
  }
  validation {
    condition     = length(var.workspace_managed_network.outbound_rules.fqdn) == 0 || alltrue([for _, v in var.workspace_managed_network.outbound_rules.fqdn : length(v.destination) > 0])
    error_message = "`destination` is required for all FQDN outbound rules."
  }
  validation {
    condition     = length(var.workspace_managed_network.outbound_rules.service_tag) == 0 || alltrue([for _, v in var.workspace_managed_network.outbound_rules.service_tag : contains(["Allow", "Deny"], v.action)])
    error_message = "The only valid options for service tag outbound rules' `action` are 'Allow' or 'Deny'."
  }
  validation {
    condition     = length(var.workspace_managed_network.outbound_rules.private_endpoint) == 0 || alltrue([for _, v in var.workspace_managed_network.outbound_rules.private_endpoint : length(v.resource_id) > 0])
    error_message = "`resource_id` is required for every private endpoint outbound rule."
  }
  validation {
    condition     = length(var.workspace_managed_network.outbound_rules.private_endpoint) == 0 || alltrue([for _, v in var.workspace_managed_network.outbound_rules.private_endpoint : length(v.sub_resource_target) > 0])
    error_message = "`sub_resource_target` is required for every private endpoint outbound rule."
  }
}
