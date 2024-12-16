# Encryption with customer-managed key

This deploys the module with a public workspace assigned to a user-assigned managed identity and encrypted with a provided customer-managed key.

Pre-created resources include:

- A Key Vault specifically for encryption
  - An RSA Key
  - The Cosmos DB service principal is assigned the Key Vault Crypto Service Encryption User for this Key Vault
- A user-assigned managed identity
  - Role assignments scoped to _resource group_:
    - Storage Account Contributor
    - Storage Account Blob Owner
    - Storage File Data Privileged Contributor
    - Key Vault Crypto Officer

The module creates:

- New Azure Machine Learning Workspace
  - New Storage Account
  - New instance of App. Insights & a new Log Analytics Workspace
  - New Key Vault instance
  - The workspace is encrypted with the pre-created RSA key
  - The user-assigned managed identity is the _primary user-assigned identity_ for the workspace


To support encryption with a customer-managed key, a Microsoft-managed resource group is created. It is named using the following convention `azureml-rg-<workspace-name>_<random GUID>`. Within it, are the follow resources:

- AI Search Service: Stores indexes that help with querying machine learning content.
- Cosmos DB Account: Stores job history data, compute metadata, and asset metadata
- Storage Account: Stores metadata related to Azure Machine Learning pipeline data.
