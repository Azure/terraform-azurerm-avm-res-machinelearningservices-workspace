# Azure Machine Learning Workspace with Image Build Compute

This example demonstrates how to create an Azure Machine Learning workspace with a custom compute cluster for image building.

## Overview

This configuration creates:

- An Azure Machine Learning workspace with all required dependencies
- Configuration for a custom compute cluster to be used for building environments
- Public network access enabled for simplicity

## Key Features

- **Custom Image Build Compute**: The `image_build_compute_name` parameter allows you to specify a compute cluster for building environments
- **Full Dependencies**: Includes all required Azure services (Storage Account, Key Vault, Container Registry, Application Insights)
- **System-assigned Managed Identity**: Uses system-assigned managed identity for authentication

## Usage

```hcl
module "azureml" {
  source = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  
  location            = "East US"
  name                = "my-aml-workspace"
  resource_group_name = "my-resource-group"
  
  # Required dependencies
  application_insights = {
    resource_id = azurerm_application_insights.example.id
  }
  container_registry = {
    resource_id = azurerm_container_registry.example.id
  }
  key_vault = {
    resource_id = azurerm_key_vault.example.id
  }
  storage_account = {
    resource_id = azurerm_storage_account.example.id
  }
  
  # Specify the compute cluster for image building
  image_build_compute_name = "my-compute-cluster"
  
  managed_identities = {
    system_assigned = true
  }
  public_network_access_enabled = true
  
  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }
}
```

## Important Notes

- The `image_build_compute_name` parameter is optional and defaults to `null` (uses default compute)
- This parameter is only supported for `Default` and `Hub` workspace types, not for `Project` workspaces
- Make sure the compute cluster exists in the workspace before using it for image building
- The compute cluster must have sufficient resources to handle the image building workload

## Variables

- `image_build_compute_name`: Name of the compute cluster to use for building environments
- `location`: Azure region where resources will be created
- `enable_telemetry`: Whether to enable telemetry for the module