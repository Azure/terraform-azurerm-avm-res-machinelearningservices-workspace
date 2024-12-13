# Encryption with customer-managed key

This deploys the module with a public workspace set to be encrypted with a provided customer-managed key.

For encryption:
- Key Vault
- User-assigned identity with access to Key Vault
- An RSA Key

- An Azure Machine Learning Workspace
  - Storage Account
  - Key Vault
  - App. Insights & Log Analytics Workspace
  - Encrypted with the RSA key
  - The user-assigned identity is assigned to the workspace

