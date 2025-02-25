# Azure Machine Learning Workspace Connection

This module provisions a connection between a service and an Azure Machine Learning Workspace / AI Foundry Hub / AI Foundry Project.

## Usage

### Example - AI Services

```hcl
module "connections" {
  source = "Azure/avm-res-machinelearningservices-workspace/azurerm//modules/connection"

  category      = "AIServices"
  credentials   = null
  shared_by_all = true
  target        = "<cog services endpoint>"
  auth_type     = "AAD"
  metadata = {
    apiType    = "Azure"
    resourceId = "<cog services account resource id>"
  }
  name         = "aiservicesaihub1"
  workspace_id = "<AI Foundry hub resource id>"
}
```

### Example - Azure OpenAI

```hcl
module "connections" {
  source = "Azure/avm-res-machinelearningservices-workspace/azurerm//modules/connection"

  category      = "AzureOpenAI"
  credentials   = null
  shared_by_all = true
  target        = "<cog services endpoint>"
  auth_type     = "AAD"
  metadata = {
    apiType    = "Azure"
    resourceId = "<cog services account resource id>"
  }
  name         = "aoiaml1"
  workspace_id = "<AML workspace resource id>"
}
```
