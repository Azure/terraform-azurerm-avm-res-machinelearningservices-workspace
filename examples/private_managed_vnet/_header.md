# Private AML workspace with managed VNet configured

This deploys the module with workspace isolation set to allow outbound Internet traffic. The resources include:

- AML Workspace (private)
- Storage Account (private)
- Key Vault (private)
- Azure Container Registry (private)
- App Insights and Log Analytics workspace

The managed VNet is not provisioned by default. In the unprovisioned state, you can see the outbound rules created in the Azure Portal or with the Azure CLI + machine learning extension `az ml workspace outbound-rule list --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE`. Since all possible provisioned resources are private, this collection should include one of type `PrivateEndpoint` for each of the following:

- Key Vault
- Storage Account: file (spark enabled)
- Storage Account: blob (spark enabled)
- Container Registry
- AML Workspace (spark enabled)

After the network is provisioned (either by adding compute or manually provisioning it with [the Azure CLI + machine learning extension](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-provision-network)), the private endpoints themselves will be created internally for Azure Machine Learning.
