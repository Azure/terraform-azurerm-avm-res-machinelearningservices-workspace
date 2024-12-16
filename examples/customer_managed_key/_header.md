# Encryption with customer-managed key

This deploys the module with a public workspace set to be encrypted with a provided customer-managed key.

Pre-created resources include:

- Key Vault
- An RSA Key

The module creates:

- an Azure Machine Learning Workspace
  - a new Storage Account
  - new App. Insights & Log Analytics Workspace
  - The workspace uses the Key Vault pre-created and is encrypted with the pre-created RSA key


To support encryption with a customer-managed key, a Microsoft-managed resource group is created. It is named using the following convention `azureml-rg-<workspace-name>_<random GUID>`. Within it, are the follow resources:

- AI Search Service: Stores indexes that help with querying machine learning content.
- Cosmos DB Account: Stores job history data, compute metadata, and asset metadata
- Storage Account: Stores metadata related to Azure Machine Learning pipeline data.
