# Azure Machine Learning Workspace Module

This is an [Azure Verified Module](https://aka.ms/avm) that provisions an Azure Machine Learning Workspace, which is a core resource for developing, training, and deploying machine learning models on Azure. Additionally, by setting the `kind` variable to `Hub`, this module can also provision an Azure AI Foundry, which is an enhanced experience built on top of the Azure Machine Learning Workspace specifically for Generative AI use cases. Finally, if the `kind` variable is set to `Project`, this module can provision an AI Foundry Project for a Hub.

## Functionality

* **Azure Machine Learning Workspace:** The default behavior of this module is to create an Azure Machine Learning Workspace, which provides the environment and tools necessary for machine learning tasks.
* **Azure AI Foundry:** If the `kind` variable is set to `Hub`, the module provisions an Azure AI Foundry Hub instead, offering additional AI capabilities while still leveraging the underlying Azure Machine Learning infrastructure.

## Usage

### Example - AML Workspace

```hcl
module "ml_workspace" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  resource_group_name = "<resource_group_name>"

  location = "<your_location>"
  kind     = "Default" # Omitting this parameter will result in the same outcome

  is_private = false # Omitting this parameter will result in the same outcome
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

  container_registry = {
    resource_id = "<container_registry_id>"
  }

  application_insights = {
    resource_id = "<app_insights_resource_id>"
  }
}
```

This will create a publicly-accessible Azure Machine Learning Workspace.

### Example - AI Foundry Hub

```hcl
module "hub" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  resource_group_name = "<resource_group_name>"

  location = "<your_location>"
  kind     = "Hub"

  is_private = false # Omitting this parameter will result in the same outcome
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

This will create a publicly-accessible AI Foundry Hub.
