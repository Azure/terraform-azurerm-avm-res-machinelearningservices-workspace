# Private AML workspace - BYO VNet

This example demonstrates provisioning a private AML workspace where network traffic is managed by the VNet it is deployed into instead of using the managed VNet.

The following resources are included:

- A VNet with a private endpoints subnet
- Private DNS zones
- Key Vault, Storage and Container Registry without public network access, connected to VNet with private endpoints
- Azure Monitor Private Link Scope (AMPLS) connected to the VNet with a private endpoint
- App. Insights and Log Analytics associated with the created AMPLS
- An AML Workspace which lacks public network access, is connected to the VNet with a private endpoint and has the workspace's managed VNet configured as "Disabled" which offloads inbound and outbound traffic management to a firewall associated with the VNet

_**Note** no firewall is included with this example._ Please refer to [MS Learn: AML inbound and outbound network traffic configuration](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-access-azureml-behind-firewall?view=azureml-api-2&tabs=ipaddress%2Cpublic) for specific requirements for an AML workspace.

