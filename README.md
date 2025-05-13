<!-- BEGIN_TF_DOCS -->
# Azure Machine Learning Workspace Module

> [!IMPORTANT]
> This module no longer provisions supporting resources, e.g. Key Vault, Storage Account and Azure Container Registry. This change was made to align with [the definition of an AVM resource module](https://azure.github.io/Azure-Verified-Modules/specs/shared/module-classifications/). The included examples in the [examples directory](examples), e.g. [AI Foundry Hub](examples/default\_ai\_foundry\_hub/README.md) and [AML Workspace](examples/default/README.md), can be used as reference for what is required to provision said resources outside of this module.

This is an [Azure Verified Module](https://aka.ms/avm) that provisions an Azure Machine Learning Workspace, which is a core resource for developing, training, and deploying machine learning models on Azure. Additionally, by setting the `kind` variable to `Hub`, this module can also provision an Azure AI Foundry, which is an enhanced experience built on top of the Azure Machine Learning Workspace specifically for Generative AI use cases. Finally, if the `kind` variable is set to `Project`, this module can provision an AI Foundry Project for a Hub.

## Functionality

* **Azure Machine Learning Workspace:** The default behavior of this module is to create an Azure Machine Learning Workspace, which provides the environment and tools necessary for machine learning tasks.
* **Azure AI Foundry:** If the `kind` variable is set to `Hub`, the module provisions an Azure AI Foundry Hub instead, offering additional AI capabilities while still leveraging the underlying Azure Machine Learning infrastructure.

## Usage

### Example - AML Workspace

```hcl
module "ml_workspace" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  resource_group_name = "<resource_group_name>"

  location = "<your_location>"
  kind     = "Default" # Omitting this parameter will result in the same outcome

  is_private = false # Omitting this parameter will result in the same outcome
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }

  storage_account = {
    resource_id = "<storage_account_resource_id>"
  }

  key_vault = {
    resource_id = "<key_vault_resource_id>"
  }

  container_registry = {
    resource_id = "<container_registry_id>"
  }

  application_insights = {
    resource_id = "<app_insights_resource_id>"
  }
}
```

This will create a publicly-accessible Azure Machine Learning Workspace.

### Example - AI Foundry Hub

```hcl
module "hub" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  resource_group_name = "<resource_group_name>"

  location   = "<your_location>"
  kind       = "Hub"
  is_private = false # Omitting this parameter will result in the same outcome

  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }

  storage_account = {
    resource_id = "<storage_account_resource_id>"
  }

  key_vault = {
    resource_id = "<key_vault_resource_id>"
  }

  aiservices = {
    resource_group_id         = "<resource_group_id>"
    name                      = "module.ai_services.name"
    create_service_connection = true
  }
}
```

This will create a publicly-accessible AI Foundry Hub.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~>0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (3.6.2)

## Resources

The following resources are used by this module:

- [azapi_resource.aiservice](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.aiserviceconnection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.computeinstance](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.hub](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.project](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint.this_unmanaged_dns_zone_groups](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/3.6.2/docs/resources/uuid) (resource)
- [azapi_resource.existing_aiservices](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azapi_resource.rg](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_key_vault_key.cmk](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_key) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this resource.

Type: `string`

### <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id)

Description: The resource group ID where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_ai_studio_hub_id"></a> [ai\_studio\_hub\_id](#input\_ai\_studio\_hub\_id)

Description: The AI Studio Hub ID for which to create a Project

Type: `string`

Default: `null`

### <a name="input_aiservices"></a> [aiservices](#input\_aiservices)

Description: An object describing the AI Services resource to create or reference. This includes the following properties:
- `create_new`: (Optional) A flag indicating if a new resource must be created. If set to 'false', both `name` and `resource_group_id` must be provided.
- `analysis_services_sku`: (Optional) When creating a new resource, this specifies the SKU of the Azure Analysis Services server. Possible values are: `D1`, `B1`, `B2`, `S0`, `S1`, `S2`, `S4`, `S8`, `S9`. Availability may be impacted by region; see https://learn.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region
- `name`: (Optional) If providing an existing resource, the name of the AI Services to reference
- `resource_group_id`: (Optional) If providing an existing resource, the id of the resource group where the AI Services resource resides
- `tags`: (Optional) Tags for the AI Services resource.
- `create_service_connection`: (Optional) Whether or not to create a service connection between the Workspace resource and AI Services resource.

Type:

```hcl
object({
    create_new                = optional(bool, false)
    analysis_services_sku     = optional(string, "S0")
    name                      = optional(string, null)
    resource_group_id         = optional(string, null)
    tags                      = optional(map(string), null)
    create_service_connection = optional(bool, false)
  })
```

Default:

```json
{
  "create_new": false
}
```

### <a name="input_application_insights"></a> [application\_insights](#input\_application\_insights)

Description: An object describing the Application Insights resource to use for monitoring inference endpoints. This includes the following properties:
- `resource_id` - (Optional) The resource ID of an existing Application Insights resource.

Type:

```hcl
object({
    resource_id = optional(string)
  })
```

Default:

```json
{
  "resource_id": null
}
```

### <a name="input_container_registry"></a> [container\_registry](#input\_container\_registry)

Description: An object describing the Container Registry. This includes the following properties:
- `resource_id` - The resource ID of an existing Container Registry, if desired.

Type:

```hcl
object({
    resource_id = optional(string)
  })
```

Default:

```json
{
  "resource_id": null
}
```

### <a name="input_create_compute_instance"></a> [create\_compute\_instance](#input\_create\_compute\_instance)

Description: Specifies whether a compute instance should be created for the workspace to provision the managed vnet. **Due to the complexity of compute instances and to prevent setting precedent that compute provisioning will be included in this module, this will be deprecated in a future release.

Type: `bool`

Default: `false`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description:   A map of diagnostic settings to create on the Azure Machine Learning Workspace. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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

Type:

```hcl
map(object({
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
```

Default: `{}`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_hbi_workspace"></a> [hbi\_workspace](#input\_hbi\_workspace)

Description: Specifies if the resource is a High Business Impact (HBI) workspace.

Type: `bool`

Default: `false`

### <a name="input_ip_allowlist"></a> [ip\_allowlist](#input\_ip\_allowlist)

Description: The list of IPv4 addresses that are allowed to access the workspace.

Type: `set(string)`

Default: `[]`

### <a name="input_is_private"></a> [is\_private](#input\_is\_private)

Description: Specifies if every provisioned resource should be private and inaccessible from the Internet.

Type: `bool`

Default: `false`

### <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault)

Description: An object describing the Key Vault required for the workspace. This includes the following properties:
- `resource_id` - The resource ID of an existing Key Vault.
- `use_microsoft_managed_key_vault` -  A flag indicating if a microsoft managed key value should be used, no new key vault will be created (preview), flag only applicable to AI Foundry (Hub).

Type:

```hcl
object({
    resource_id                     = optional(string)
    use_microsoft_managed_key_vault = optional(bool, false)
  })
```

Default:

```json
{
  "resource_id": null
}
```

### <a name="input_kind"></a> [kind](#input\_kind)

Description: The kind of the resource. This is used to determine the type of the resource. If not specified, the resource will be created as a standard resource.  
Possible values are:
- `Default` - The resource will be created as a standard Azure Machine Learning resource.
- `Hub` - The resource will be created as an AI Hub resource.
- `Project` - The resource will be created as an AI Studio Project resource.

Type: `string`

Default: `"Default"`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls)

Description: Specifies the network access control list (ACL) for the workspace. This includes the following properties:
- `default_action`: The default action for the network ACL. Possible values are `Allow` and `Deny`.
- `ip_rules`: A list of IP rules to apply to the network ACL. Each rule is an object with a `value` property that specifies the IP address or CIDR range.

Type:

```hcl
object({
    default_action = string,
    ip_rules = list(object({
      value = string
    }))
  })
```

Default: `null`

### <a name="input_outbound_rules"></a> [outbound\_rules](#input\_outbound\_rules)

Description:   A map of private endpoints outbound rules for the managed network. **This will be deprecated in favor of the `var.workspace_managed_network.outbound_rules` in a future release. Until then, the final outbound rules of type 'PrivateEndpoint' will be a combination of this variable's value and that of `workspace_managed_network.outbound_rules.private_endpoint`.

  - `resource_id` - The resource id for the corresponding private endpoint.
  - `sub_resource_target` - The sub\_resource\_target is target for the private endpoint. e.g. account for Openai, searchService for Azure Ai Search

Type:

```hcl
map(object({
    resource_id         = string
    sub_resource_target = string
  }))
```

Default: `{}`

### <a name="input_primary_user_assigned_identity"></a> [primary\_user\_assigned\_identity](#input\_primary\_user\_assigned\_identity)

Description: The resource id of the primary user-assigned managed identity for the workspace.

Type:

```hcl
object({
    resource_id = optional(string, null)
  })
```

Default: `{}`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description:   A map of private endpoints to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
    - `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
    - `principal_id` - The ID of the principal to assign the role to.
    - `description` - (Optional) The description of the role assignment.
    - `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
    - `condition` - (Optional) The condition which will be used to scope the role assignment.
    - `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
    - `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
    - `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.
  - `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
    - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
    - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  - `tags` - (Optional) A mapping of tags to assign to the private endpoint.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
  - `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of the Key Vault.
  - `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
    - `name` - The name of the IP configuration.
    - `private_ip_address` - The private IP address of the IP configuration.

Type:

```hcl
map(object({
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
    tags               = optional(map(string), null)
    subnet_resource_id = string
    #subresource_name                        = string # NOTE: `subresource_name` can be excluded if the resource does not support multiple sub resource types (e.g. storage account supports blob, queue, etc)
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
```

Default: `{}`

### <a name="input_private_endpoints_manage_dns_zone_group"></a> [private\_endpoints\_manage\_dns\_zone\_group](#input\_private\_endpoints\_manage\_dns\_zone\_group)

Description: Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy.

Type: `bool`

Default: `true`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_storage_access_type"></a> [storage\_access\_type](#input\_storage\_access\_type)

Description: The authentication mode used for accessing the system datastores of the workspace. Valid options include 'accessKey' and 'identity'. **This will be deprecated once the version of ARM used with the azapi provider is updated from 2024-07-01-preview as it was removed from the schema.

Type: `string`

Default: `"identity"`

### <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account)

Description: An object describing the Storage Account for the workspace. This includes the following properties:

- `resource_id` - The resource ID of an existing Storage Account.

Type:

```hcl
object({
    resource_id = optional(string)
  })
```

Default:

```json
{
  "resource_id": null
}
```

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_workspace_description"></a> [workspace\_description](#input\_workspace\_description)

Description: The description of this workspace.

Type: `string`

Default: `""`

### <a name="input_workspace_friendly_name"></a> [workspace\_friendly\_name](#input\_workspace\_friendly\_name)

Description: The friendly name for this workspace. This value in mutable.

Type: `string`

Default: `"Workspace"`

### <a name="input_workspace_managed_network"></a> [workspace\_managed\_network](#input\_workspace\_managed\_network)

Description: Specifies properties of the workspace's managed virtual network.

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
- `firewall_sku`: The SKU of the Azure Firewall. Valid options are 'Basic' or 'Standard'. Default is 'Standard'.

Type:

```hcl
object({
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
    firewall_sku = optional(string, "Standard")
  })
```

Default:

```json
{
  "firewall_sku": "Standard",
  "isolation_mode": "Disabled",
  "spark_ready": true
}
```

## Outputs

The following outputs are exported:

### <a name="output_ai_services"></a> [ai\_services](#output\_ai\_services)

Description: The AI Services resource, if created.

### <a name="output_ai_services_service_connection"></a> [ai\_services\_service\_connection](#output\_ai\_services\_service\_connection)

Description: The service connection between the AIServices and the workspace, if created.

### <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints)

Description: A map of the private endpoints created.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The machine learning workspace.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the machine learning workspace.

### <a name="output_workspace"></a> [workspace](#output\_workspace)

Description: The machine learning workspace created.

### <a name="output_workspace_identity"></a> [workspace\_identity](#output\_workspace\_identity)

Description: The identity for the created workspace.

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->