<!-- BEGIN_TF_DOCS -->
## Azure Machine Learning Workspace Module

### Overview

This is an [Azure Verified Module](https://aka.ms/avm) that provisions an Azure Machine Learning Workspace, which is a core resource for developing, training, and deploying machine learning models on Azure. Additionally, by setting the `kind` variable to `Hub`, this module can also provision an Azure AI Studio, which is an enhanced experience built on top of the Azure Machine Learning Workspace specifically for Generative AI use cases. Finally, if the `kind` variable is set to `Project`, this module can provision a AI Studio Project for a Hub workspace.

### Functionality

* **Azure Machine Learning Workspace:** The default behavior of this module is to create an Azure Machine Learning Workspace, which provides the environment and tools necessary for machine learning tasks.
* **Azure AI Studio:** If the `kind` variable is set to `Hub`, the module provisions an Azure AI Studio instead, offering additional AI capabilities while still leveraging the underlying Azure Machine Learning infrastructure.

### Example Usage

```hcl
module "ml_workspace" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  resource_group_name = "<resource_group_name>"

  location = "<your_location>"
  kind     = "Default" # Omitting this parameter will result in the same outcome
}
```

This will create an Azure Machine Learning Workspace.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (>= 1.14.0, < 2.0.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (3.115)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (0.3.2)

- <a name="requirement_random"></a> [random](#requirement\_random) (3.6.2)

## Resources

The following resources are used by this module:

- [azapi_resource.aiservice](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.aiserviceconnection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.computeinstance](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.hub](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.project](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.this](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/resources/management_lock) (resource)
- [azurerm_monitor_diagnostic_setting.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/resources/private_endpoint_application_security_group_association) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/Azure/modtm/0.3.2/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/3.6.2/docs/resources/uuid) (resource)
- [azapi_resource.existing_aiservices](https://registry.terraform.io/providers/Azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/data-sources/client_config) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/data-sources/client_config) (data source)
- [azurerm_resource_group.current](https://registry.terraform.io/providers/hashicorp/azurerm/3.115/docs/data-sources/resource_group) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/Azure/modtm/0.3.2/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the this resource.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

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

Description: An object describing the Application Insights resource to create or use for monitoring inference endpoints. This includes the following properties:
- `resource_id` - (Optional) The resource ID of an existing Application Insights resource.
- `create_new` - A flag indicating if a new resource must be created.
- `tags` - (Optional) Tags for a new Application Insights resource.
- `log_analytics_workspace` - An object describing the Log Analytics Workspace for the Application Insights resource
  - `resource_id` - The resource ID of an existing Log Analytics Workspace.
  - `create_new` - A flag indicating if a new workspace must be created.
  - `tags` - (Optional) Tags for the Log Analytics Workspace resource.

Type:

```hcl
object({
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
```

Default:

```json
{
  "create_new": false
}
```

### <a name="input_container_registry"></a> [container\_registry](#input\_container\_registry)

Description: An object describing the Container Registry. This includes the following properties:
- `resource_id` - The resource ID of an existing Container Registry, set to null if a new Container Registry should be created.
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

Type:

```hcl
object({
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
```

Default:

```json
{
  "create_new": false
}
```

### <a name="input_create_compute_instance"></a> [create\_compute\_instance](#input\_create\_compute\_instance)

Description: Specifies whether a compute instance should be created for the workspace to provision the managed vnet.

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

### <a name="input_is_private"></a> [is\_private](#input\_is\_private)

Description: Specifies if every provisioned resource should be private and inaccessible from the Internet.

Type: `bool`

Default: `false`

### <a name="input_key_vault"></a> [key\_vault](#input\_key\_vault)

Description: An object describing the Key Vault to create the private endpoint connection to. This includes the following properties:
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

Type:

```hcl
object({
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
```

Default:

```json
{
  "create_new": true
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

### <a name="input_outbound_rules"></a> [outbound\_rules](#input\_outbound\_rules)

Description:   A map of private endpoints toutbound rules for the managed network.

  - `resource_id` - The resource id for the corresponding private endpoint.
  - `sub_resource_target` - The sub\_resource\_target is target for the private endpoint. e.g. account for Openai, searchService for Azure Ai Search

Type:

```hcl
map(object({
    resource_id         = string
    sub_resource_target = string
  }))
```

Default: `null`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description: A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

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
```

Default: `{}`

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

### <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account)

Description: An object describing the Storage Account. This includes the following properties:
- `resource_id` - The resource ID of an existing Storage Account, set to null if a new Storage Account should be created.
- `private_endpoints` - A map of private endpoints to create on a newly created Storage Account. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
  - `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
  - `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
  - `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
  - `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
  - `inherit_lock` - (Optional) If set to true, the private endpoint will inherit the lock from the parent resource. Defaults to false.
- `tags` - (Optional) Tags for the Storage Account resource.

Type:

```hcl
object({
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
```

Default:

```json
{
  "create_new": true
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

Possible values for `isolation_mode` are:
- 'Disabled': Inbound and outbound traffic is unrestricted _or_ BYO VNet to protect resources.
- 'AllowInternetOutbound': Allow all internet outbound traffic.
- 'AllowOnlyApprovedOutbound': Outbound traffic is allowed by specifying service tags.  
While is possible to update the workspace to enable network isolation ('AllowInternetOutbound' or 'AllowOnlyApprovedOutbound'), it is not possible to disable it on a workspace with it enabled.

`spark_ready` determines whether spark jobs will be run on the network. This value can be updated in the future.

Type:

```hcl
object({
    isolation_mode = string
    spark_ready    = optional(bool, true)
  })
```

Default:

```json
{
  "isolation_mode": "Disabled",
  "spark_ready": true
}
```

## Outputs

The following outputs are exported:

### <a name="output_application_insights"></a> [application\_insights](#output\_application\_insights)

Description: The ID of the application insights.

### <a name="output_container_registry"></a> [container\_registry](#output\_container\_registry)

Description: The container registry resource.

### <a name="output_key_vault"></a> [key\_vault](#output\_key\_vault)

Description: The key vault resource.

### <a name="output_private_endpoints"></a> [private\_endpoints](#output\_private\_endpoints)

Description:   A map of the private endpoints created.

### <a name="output_resource"></a> [resource](#output\_resource)

Description: The machine learning workspace.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The ID of the machine learning workspace.

### <a name="output_storage_account"></a> [storage\_account](#output\_storage\_account)

Description: The storage account resource.

## Modules

The following Modules are called:

### <a name="module_avm_res_containerregistry_registry"></a> [avm\_res\_containerregistry\_registry](#module\_avm\_res\_containerregistry\_registry)

Source: Azure/avm-res-containerregistry-registry/azurerm

Version: ~> 0.1

### <a name="module_avm_res_insights_component"></a> [avm\_res\_insights\_component](#module\_avm\_res\_insights\_component)

Source: Azure/avm-res-insights-component/azurerm

Version: ~> 0.1

### <a name="module_avm_res_keyvault_vault"></a> [avm\_res\_keyvault\_vault](#module\_avm\_res\_keyvault\_vault)

Source: Azure/avm-res-keyvault-vault/azurerm

Version: ~> 0.9.1

### <a name="module_avm_res_log_analytics_workspace"></a> [avm\_res\_log\_analytics\_workspace](#module\_avm\_res\_log\_analytics\_workspace)

Source: Azure/avm-res-operationalinsights-workspace/azurerm

Version: 0.3.3

### <a name="module_avm_res_storage_storageaccount"></a> [avm\_res\_storage\_storageaccount](#module\_avm\_res\_storage\_storageaccount)

Source: Azure/avm-res-storage-storageaccount/azurerm

Version: ~> 0.1

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->