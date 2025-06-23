# Azure Machine Learning Workspace Module

This is an [Azure Verified Module](https://aka.ms/avm) that provisions an Azure Machine Learning Workspace, which is a core resource for developing, training, and deploying machine learning models on Azure. Additionally, by setting the `kind` variable to `Hub`, this module can also provision an Azure AI Hub, which is an enhanced experience built on top of the Azure Machine Learning Workspace specifically for Generative AI use cases. Finally, if the `kind` variable is set to `Project`, this module can provision an AI Project for a Hub.

## Functionality

* **Azure Machine Learning Workspace:** The default behavior of this module is to create an Azure Machine Learning Workspace, which provides the environment and tools necessary for machine learning tasks.
* **Azure AI Hub:** If the `kind` variable is set to `Hub`, the module provisions an Azure AI Hub instead, offering additional AI capabilities while still leveraging the underlying Azure Machine Learning infrastructure.

## Usage

### Example - AML Workspace

This will create a publicly-accessible Azure Machine Learning Workspace.

```hcl
module "ml_workspace" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  location            = "<your_location>"
  name                = "<workspace_name>"
  resource_group_name = "<resource_group_name>"
  kind                = "Default" # Omitting this parameter will result in the same outcome

  application_insights = {
    resource_id = "<app_insights_resource_id>"
  }

  container_registry = {
    resource_id = azurerm_container_registry.example.id
  }

  key_vault = {
    resource_id = "<key_vault_resource_id>"
  }

  managed_identities = {
    system_assigned = true
  }

  public_network_access_enabled = true

  storage_account = {
    resource_id = "<storage_account_resource_id>"
  }

  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }
}
```

### Example - AI Hub

This will create a publicly-accessible AI Hub.

```hcl
module "hub" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  location            = "<your_location>"
  name                = "<hub_name>"
  resource_group_name = "<resource_group_name>"
  kind                = "Hub"

  workspace_managed_network = {
    isolation_mode = "Disabled"
    spark_ready    = true
  }

  storage_account = {
    resource_id = "<storage_account_resource_id>"
  }

  key_vault = {
    resource_id = "<key_vault_resource_id>"
  }
}
```
