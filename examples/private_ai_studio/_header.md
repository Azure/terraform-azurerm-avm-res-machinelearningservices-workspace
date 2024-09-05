# Azure AI Hub

This deploys the following:

- Azure VNet
  - subnet named "private_endpoints"
- 4 private DNS zones linked to the VNet
  - "privatelink.api.azureml.ms" for the AI Studio Hub
  - "privatelink.notebooks.azure.net" for the AI Studio Hub
  - "privatelink.vaultcore.azure.net" for Key Vault
  - "privatelink.blob.core.windows.net" for Blob Storage Account

The Resource module deploys:

- AI Hub workspace (private) with a private endpoint in the "private_endpoints" subnet, referencing both "privatelink.api.azureml.ms" and "privatelink.notebooks.azure.net" DNS zones
- Storage Account (private) with a private endpoint in the "private_endpoints" subnet, referencing the "privatelink.blob.core.windows.net" DNS zone
- Key Vault (private) with a private endpoint in the "private_endpoints" subnet, referencing the "privatelink.vaultcore.azure.net" DNS zone
- App Insights and Log Analytics workspace
- AI Services + an AI Services Connection to the Hub

The managed VNet is not provisioned by default. In the unprovisioned state, you can see the outbound rules created in the Azure Portal or with the Azure CLI + machine learning extension `az ml workspace outbound-rule list --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE`. Since all possible provisioned resources are private, this collection should include one of type `PrivateEndpoint` for each of the following:

- Key Vault
- Storage Account: file (spark enabled)
- Storage Account: blob (spark enabled)
- The AI Hub Workspace (spark enabled)

After the network is provisioned (either by adding compute or manually provisioning it with [the Azure CLI + machine learning extension](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-provision-network)), the private endpoints themselves will be created internally for AI Studio.
