# Dependent resources for Azure Machine Learning
resource "azurerm_application_insights" "default" {
  name                = "mvnet-${var.prefix}-${var.environment}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  application_type    = "web"
}

resource "random_string" "kv_prefix" {
  length  = 4
  upper   = false
  special = false
  numeric = false
}

resource "azurerm_key_vault" "default" {
  name                     = "kv-${random_string.kv_prefix.result}-${var.environment}"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
  public_network_access_enabled = false
}

resource "random_string" "sa_prefix" {
  length  = 4
  upper   = false
  special = false
  numeric = false
}

resource "azurerm_storage_account" "default" {
  name                     = "sa${random_string.sa_prefix.result}${var.environment}"
  location                 = azurerm_resource_group.default.location
  resource_group_name      = azurerm_resource_group.default.name
  account_tier             = "Standard"
  account_replication_type = "GRS"

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
  public_network_access_enabled = false
}

resource "azurerm_container_registry" "default" {
  name                = "acr${var.prefix}${var.environment}"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = "Premium"
  admin_enabled       = true

  network_rule_set {
    default_action = "Deny"
  }
  public_network_access_enabled = false
}

resource "azapi_resource" "aml_workspace" {
  type = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name = "${var.prefix}mvnetws"
  location = var.location
  parent_id = azurerm_resource_group.default.id
  tags = {
    vnettype = "managed"    
  }
  identity {
    type = "SystemAssigned"
  } 
    body = jsonencode({
    properties = {
      publicNetworkAccess = "Disabled"
      applicationInsights = azurerm_application_insights.default.id
      containerRegistry = azurerm_container_registry.default.id
      hbiWorkspace = true
      friendlyName = "AMLManagedVirtualNetwork"
    #   imageBuildCompute = azurerm_machine_learning_compute_cluster.image-builder.id
      keyVault = azurerm_key_vault.default.id
      managedNetwork = {
        isolationMode = "AllowInternetOutbound"
        status = {
          sparkReady = true
          status = "Active"
        }
      }
      storageAccount = azurerm_storage_account.default.id
    }
    kind = "hub"
  })
}
# Compute cluster for image building required since the workspace is behind a vnet.
# For more details, see https://docs.microsoft.com/en-us/azure/machine-learning/tutorial-create-secure-workspace#configure-image-builds.
# resource "azurerm_machine_learning_compute_cluster" "mvnetimagebuilder" {
#   name                          = var.image_build_compute_name
#   location                      = azurerm_resource_group.default.location
#   vm_priority                   = "LowPriority"
#   vm_size                       = "Standard_DS2_v2"
#   machine_learning_workspace_id = azapi_resource.aml_workspace.id
#   scale_settings {
#     min_node_count                       = 0
#     max_node_count                       = 2
#     scale_down_nodes_after_idle_duration = "PT15M" # 15 minutes
#   }

#   identity {
#     type = "SystemAssigned"
#   }
# }
