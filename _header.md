## Azure Machine Learning Workspace Module

### Overview

This is an [Azure Verified Module](https://aka.ms/avm) that provisions an Azure Machine Learning Workspace, which is a core resource for developing, training, and deploying machine learning models on Azure. Additionally, by setting the `kind` variable to `hub`, this module can also provision an Azure AI Studio, which is an enhanced experience built on top of the Azure Machine Learning Workspace.

### Functionality

* **Azure Machine Learning Workspace:** The default behavior of this module is to create an Azure Machine Learning Workspace, which provides the environment and tools necessary for machine learning tasks.
* **Azure AI Studio:** If the `kind` variable is set to `hub`, the module provisions an Azure AI Studio instead, offering additional AI capabilities while still leveraging the underlying Azure Machine Learning infrastructure.

### Example Usage

```hcl
module "ml_workspace" {
  source  = "Azure/avm-res-machinelearningservices-workspace/azurerm"
  version = "x.x.x"

  resource_group = {
    name = "<resource_group_name>"
    id   = "<resource_group_id>"
  }

  location = "<your_location>"
  kind     = "hub" # Set to 'hub' for Azure AI Studio, or omit for Azure ML Workspace
}
```

This will create an Azure Machine Learning Workspace or, if `kind` is set to `hub`, an Azure AI Studio.
