# Private AML workspace with managed VNet configured

This deploys the module with workspace isolation set to allow outbound Internet traffic.

The following resources are included:

- Azure VNet with a subnet for private endpoints
- AML Workspace (private) with associated private DNS zones
- Storage Account (private) with associated private DNS zones
- Key Vault (private) with associated private DNS zone
- Azure Container Registry (private) with associated private DNS zone
- Azure Monitor Private Link Scope (AMPLS) connected to the VNet with a private endpoint with required DNS zones
- App Insights and AMPLS scoped service
- Log Analytics Workspace and AMPLS scoped service

_**Note** AMPLS is configured for open ingestion and query access._ Best practice would have these updated to `PrivateOnly` after every relevant resource was added to it. This is not done in this example, but could be achieved with the following using the azapi Terraformed provider:

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

The managed VNet is not provisioned by default. In the unprovisioned state, you can see the outbound rules created in the Azure Portal or with the Azure CLI + machine learning extension `az ml workspace outbound-rule list --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE`. Since all possible provisioned resources are private, this collection should include one of type `PrivateEndpoint` for each of the following:

- Key Vault
- Storage Account: file (spark enabled)
- Storage Account: blob (spark enabled)
- Container Registry
- AML Workspace (spark enabled)

After the network is provisioned (either by adding compute or manually provisioning it with [the Azure CLI + machine learning extension](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-provision-network)), the private endpoints themselves will be enabled for the AML workspace.
