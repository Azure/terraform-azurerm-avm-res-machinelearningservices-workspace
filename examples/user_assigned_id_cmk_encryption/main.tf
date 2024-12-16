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

locals {
  cosmos_db_id              = "a232010e-820c-4083-83bb-3ace5fc29d0b" # **FOR AZURE GOV** use "57506a73-e302-42a9-b869-6f12d9ec29e9"
  key_name                  = module.naming.key_vault_key.name_unique
  kv_admin_role             = "/providers/Microsoft.Authorization/roleDefinitions/00482a5a-887f-4fb3-b363-3b7fe8e74483" # Key Vault Administrator
  kv_crypto_officer_role    = "/providers/Microsoft.Authorization/roleDefinitions/14b46e9e-c2b7-41b4-b07b-48a6ebf60603" # Key Vault Crypto Officer
  kv_crypto_role            = "/providers/Microsoft.Authorization/roleDefinitions/e147488a-f6f5-4113-8e2d-b22465e65bf6" # Key Vault Crypto Service Encryption User
  storage_acct_contrib_role = "/providers/Microsoft.Authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab" # Storage Account Contributor
  storage_blob_owner_role   = "/providers/Microsoft.Authorization/roleDefinitions/b7e6dc6d-f1e8-4753-8033-0f276bb0955b" # Storage Account Blob Owner
  storage_file_priv_role    = "/providers/Microsoft.Authorization/roleDefinitions/69566ab7-960f-475b-8e7c-b3118f30c6bd" # Storage File Data Privileged Contributor
}

resource "azurerm_user_assigned_identity" "cmk" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_role_assignment" "storagecontrib" {
  principal_id       = azurerm_user_assigned_identity.cmk.principal_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = local.storage_acct_contrib_role
}

resource "azurerm_role_assignment" "blob" {
  principal_id       = azurerm_user_assigned_identity.cmk.principal_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = local.storage_blob_owner_role
}

resource "azurerm_role_assignment" "filepriv" {
  principal_id       = azurerm_user_assigned_identity.cmk.principal_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = local.storage_file_priv_role
}

resource "azurerm_role_assignment" "crypto" {
  principal_id       = azurerm_user_assigned_identity.cmk.principal_id
  scope              = azurerm_resource_group.this.id
  role_definition_id = local.kv_crypto_officer_role
}

# create a keyvault for storing the credential with RBAC for the deployment user
module "avm_res_keyvault_vault" {
  source              = "Azure/avm-res-keyvault-vault/azurerm"
  version             = "~> 0.9.1"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  name                = module.naming.key_vault.name_unique
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  network_acls = {
    default_action = "Allow"
  }

  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = local.kv_admin_role
      principal_id               = data.azurerm_client_config.current.object_id
    }

    cosmos_db = {
      role_definition_id_or_name       = local.kv_crypto_role
      principal_id                     = local.cosmos_db_id
      skip_service_principal_aad_check = true # because it isn't a traditional SP
    }
  }

  keys = {
    encrypt = {
      name     = local.key_name
      key_type = "RSA"
      key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "unwrapKey",
        "verify",
        "wrapKey"
      ]
      key_size = 2048
    }
  }

  wait_for_rbac_before_key_operations = {
    create = "70s"
  }
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
    system_assigned            = false
    user_assigned_resource_ids = [azurerm_user_assigned_identity.cmk.id]
  }

  customer_managed_key = {
    key_name              = local.key_name
    key_vault_resource_id = module.avm_res_keyvault_vault.resource_id
    user_assigned_identity = {
      resource_id = azurerm_user_assigned_identity.cmk.id
    }
  }

  primary_user_assigned_identity = {
    resource_id = azurerm_user_assigned_identity.cmk.id
  }

  enable_telemetry = var.enable_telemetry

  depends_on = [module.avm_res_keyvault_vault]
}
