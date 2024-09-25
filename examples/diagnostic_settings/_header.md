# AML Workspace with Diagnostic Settings

This deploys a public Azure Machine Learning Workspace using existing resources. The resource group, storage account, key vault, container registry, application insights and log analytics workspace are all provided to the module. Additionally, an instance of Azure Monitor diagnostic setting is provisioned for the Workspace -- all metrics and all logs, dedicated (separate) log analytics workspace and storage account.
