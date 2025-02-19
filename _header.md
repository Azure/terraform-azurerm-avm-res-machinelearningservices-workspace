# Azure Machine Learning Workspace Module

> [!IMPORTANT]
> This module no longer provisions supporting resources, e.g. Key Vault, Storage Account and Azure Container Registry. This change was made to align with [the definition of an AVM resource module](https://azure.github.io/Azure-Verified-Modules/specs/shared/module-classifications/). The included examples in the [examples directory](examples), e.g. [AI Foundry Hub](examples/default_ai_foundry_hub/README.md) and [AML Workspace](examples/default/README.md), can be used as reference for what is required to provision said resources outside of this module.

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

  location   = "<your_location>"
  kind       = "Hub"
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

  aiservices = {
    resource_group_id         = "<resource_group_id>"
    name                      = "module.ai_services.name"
    create_service_connection = true
  }
}
```

This will create a publicly-accessible AI Foundry Hub.
