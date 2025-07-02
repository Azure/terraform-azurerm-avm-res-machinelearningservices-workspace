# Private AML workspace - BYO VNet

This example demonstrates provisioning a private AML workspace where network traffic is managed by the VNet it is deployed into instead of using the managed VNet.

The following resources are included:

- A VNet with a private endpoints subnet
- Private DNS zones
- Key Vault, Storage and Container Registry without public network access, connected to VNet with private endpoints
- Azure Monitor Private Link Scope (AMPLS) connected to the VNet with a private endpoint with required DNS zones
- App Insights and AMPLS scoped service
- Log Analytics Workspace and AMPLS scoped service
- An AML Workspace which lacks public network access, is connected to the VNet with a private endpoint and has the workspace's managed VNet configured as "Disabled" which offloads inbound and outbound traffic management to a firewall associated with the VNet

_**Note** no firewall is included with this example._ Please refer to [MS Learn: AML inbound and outbound network traffic configuration](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-access-azureml-behind-firewall?view=azureml-api-2&tabs=ipaddress%2Cpublic) for specific requirements for an AML workspace.

_**Additionally** AMPLS is configured for open ingestion and query access._ Best practice would have these updated to `PrivateOnly` after every relevant resource was added to it. This is not done in this example, but could be achieved with the following using the azapi Terraformed provider:

```terraform
ephemeral "azapi_resource_action" "update_monitor_private_link_scope" {
  method      = "PUT"
  resource_id = azurerm_monitor_private_link_scope.example.id
  type        = "Microsoft.Insights/privateLinkScopes@2023-06-01-preview"
  body = {
    location = "Global"
    properties = {
      accessModeSettings = {
        ingestionAccessMode = "PrivateOnly"
        queryAccessMode     = "PrivateOnly"
      }
    }
  }
}
```
