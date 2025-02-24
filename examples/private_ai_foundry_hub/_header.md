# Azure AI Hub

This example deploys the core aspects of the architecture depicted in the image below.

![An architecture diagram. At the top, a Managed VNet containing a compute instance, serverless compute, a managed online endpoint and AI project is depicted. A private endpoint within the Managed VNet connects to the Azure AI Studio hub. There are also private endpoints connecting an Azure Storage Account, Azure Key Vault and Azure Container Registry to the Managed VNet. Azure AI Services, Azure Open AI and, optionally, Azure AI Search are accessible within the Managed VNet as well. In the middle left, there is an Azure VNet labeled 'Your Azure VNet' which serves as a bridge between an on-premise network and Azure resources with various private endpoints.](https://learn.microsoft.com/en-us/azure/ai-studio/media/how-to/network/azure-ai-network-outbound.png)

This specifically includes:

- 1 Azure VNet
  - subnet named "private_endpoints"
- 6 private DNS zones linked to the VNet
  - "privatelink.api.azureml.ms" for the AI Foundry Hub
  - "privatelink.notebooks.azure.net" for the AI Foundry Hub
  - "privatelink.vaultcore.azure.net" for Key Vault
  - "privatelink.blob.core.windows.net" for Storage Account (blob)
  - "privatelink.file.core.windows.net" for Storage Account (file)
  - "privatelink.azurecr.io" for Container Registry
- AI Foundry Hub workspace (private)
  - 1 private endpoint in the "private_endpoints" subnet referencing both "privatelink.api.azureml.ms" and "privatelink.notebooks.azure.net" DNS zones
- Storage Account (private)
  -  1 private endpoint in the "private_endpoints" subnet referencing the "privatelink.blob.core.windows.net" DNS zone and 
  -  1 private endpoint in the "private_endpoints" subnet referencing DNS zone "privatelink.file.core.windows.net"
- Key Vault (private)
  - 1 private endpoint in the "private_endpoints" subnet, referencing the "privatelink.vaultcore.azure.net" DNS zone
- Azure Container Registry (private)
  - 1 private endpoint in the "private_endpoints" subnet, referencing the "privatelink.azurecr.io" DNS zone
- App Insights and Log Analytics workspace
- AI Services + an AI Services Connection to the Hub

The managed VNet is not provisioned by default. In the unprovisioned state, you can see the outbound rules created in the Azure Portal or with the Azure CLI + machine learning extension `az ml workspace outbound-rule list --resource-group $RESOURCE_GROUP --workspace-name $WORKSPACE`. Since all possible provisioned resources are private, this collection should include one of type `PrivateEndpoint` for each of the following:

- Key Vault
- Storage Account: file (spark enabled)
- Storage Account: blob (spark enabled)
- Container Registry
- The AI Hub Workspace (spark enabled)

After the network is provisioned (either by adding compute or manually provisioning it with [the Azure CLI + machine learning extension](https://learn.microsoft.com/en-us/cli/azure/ml/workspace?view=azure-cli-latest#az-ml-workspace-provision-network)), the private endpoints themselves will be created internally for AI Studio.
