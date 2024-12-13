terraform {
  required_version = "~> 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116.0, < 4.0.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  storage_use_azuread = true
}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = var.location
  name     = module.naming.resource_group.name_unique
}

data "azurerm_client_config" "current" {}

resource "azurerm_user_assigned_identity" "example_identity" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

locals {
  cosmos_db_id = "a232010e-820c-4083-83bb-3ace5fc29d0b" # **FOR AZURE GOV** use "57506a73-e302-42a9-b869-6f12d9ec29e9"
}

# create a keyvault for storing the credential with RBAC for the deployment user
module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "~> 0.9.1"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = "encrypt-${module.naming.key_vault.name_unique}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }

    customer_managed_key = {
      role_definition_id_or_name = "Key Vault Crypto Officer"
      principal_id               = azurerm_user_assigned_identity.example_identity.principal_id
    }

    cosmos_db = {
      role_definition_id_or_name       = "Key Vault Crypto Service Encryption User"
      principal_id                     = local.cosmos_db_id
      skip_service_principal_aad_check = true # because it isn't a traditional SP
    }
  }

  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
  wait_for_rbac_before_key_operations = {
    create = "60s"
  }
}

# create a Customer Managed Key for a Storage Account.
resource "azurerm_key_vault_key" "example" {
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  key_type     = "RSA"
  key_vault_id = module.avm_res_keyvault_vault.resource_id
  name         = module.naming.key_vault_key.name_unique
  key_size     = 2048

  depends_on = [module.avm_res_keyvault_vault]
}


# This is the module call
module "azureml" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = azurerm_resource_group.this.location
  name                = module.naming.machine_learning_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name

  application_insights = {
    create_new = true
    log_analytics_workspace = {
      create_new = true
    }
  }

  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.example_identity.id]
  }

  customer_managed_key = {
    key_name              = azurerm_key_vault_key.example.name
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.example_identity.id
    }
  }

  enable_telemetry = var.enable_telemetry
}
