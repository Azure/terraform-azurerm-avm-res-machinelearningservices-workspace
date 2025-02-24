# Private AML workspace with managed VNet configured

This deploys the module with workspace isolation set to allow outbound Internet traffic.

The following resources are included:

- Azure VNet with a subnet for private endpoints
- AML Workspace (private) with associated private DNS zones
- Storage Account (private) with associated private DNS zones
- Key Vault (private) with associated private DNS zone
- Azure Container Registry (private) with associated private DNS zone
- Azure Monitor Private Link Scope (AMPLS) with associated private DNS zones
- App Insights and Log Analytics workspace associated with the created AMPLS

The managed VNet is not provisioned by default. In the unprovisioned state, you can see the outbound rules created in the Azure Portal or with the Azure CLI + machine learning extension `az ml workspace outbound-rule list --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE`. Since all possible provisioned resources are private, this collection should include one of type `PrivateEndpoint` for each of the following:

- Key Vault
- Storage Account: file (spark enabled)
- Storage Account: blob (spark enabled)
- Container Registry
- AML Workspace (spark enabled)

After the network is provisioned (either by adding compute or manually provisioning it with [the Azure CLI + machine learning extension](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-provision-network)), the private endpoints themselves will be enabled for the AML workspace.
