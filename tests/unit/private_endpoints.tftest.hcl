mock_provider "azapi" {
  mock_resource "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.MachineLearningServices/workspaces/unit-workspace"
    }
  }
}

mock_provider "azurerm" {
  mock_data "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg"
    }
  }
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/privateEndpoints/unit-endpoint"
    }
  }
}

mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name                = "unit-workspace"
  resource_group_name = "unit-rg"
  location            = "uksouth"
  managed_identities = {
    system_assigned = true
  }
  key_vault = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.KeyVault/vaults/unit-vault"
  }
  storage_account = {
    resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Storage/storageAccounts/unitstorage"
  }
}

run "workspace_without_endpoints" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  assert {
    condition     = length(output.private_endpoints) == 0 && length(azapi_resource.this) == 1 && length(azapi_resource.hub) == 0 && length(azapi_resource.project) == 0
    error_message = "The default workspace address and empty endpoint defaults must be preserved."
  }
  assert {
    condition     = azapi_resource.this[0].identity[0].type == "SystemAssigned"
    error_message = "The workspace must retain its system-assigned identity."
  }
}

run "managed_endpoint_defaults" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
        ip_configurations = {
          default = {
            name               = "default"
            private_ip_address = "10.0.0.5"
          }
        }
      }
    }
  }
  assert {
    condition     = azurerm_private_endpoint.this["endpoint"].ip_configuration[0].member_name == "default" && azurerm_private_endpoint.this["endpoint"].ip_configuration[0].subresource_name == "amlworkspace"
    error_message = "Existing callers must retain the default static IP member and workspace subresource."
  }
  assert {
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0 && length(azurerm_private_endpoint.this["endpoint"].private_dns_zone_group) == 0 && output.private_endpoints["endpoint"].id == azurerm_private_endpoint.this["endpoint"].id
    error_message = "An endpoint without zone IDs must not create a zone group or change its address."
  }
  assert {
    condition     = length(azurerm_role_assignment.private_endpoints) == 0 && length(azurerm_management_lock.private_endpoints) == 0
    error_message = "Endpoint role assignments and locks must remain opt-in."
  }
}

run "managed_endpoint_extensions" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        name                            = "custom-endpoint"
        subnet_resource_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
        subresource_name                = "amlworkspace"
        private_dns_zone_group_name     = "custom-group"
        private_dns_zone_resource_ids   = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms"]
        location                        = "westeurope"
        resource_group_name             = "endpoint-rg"
        network_interface_name          = "endpoint-nic"
        private_service_connection_name = "endpoint-connection"
        tags = {
          purpose = "unit"
        }
        application_security_group_associations = {
          clients = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/applicationSecurityGroups/clients"
        }
        ip_configurations = {
          notebook = {
            name               = "notebook"
            private_ip_address = "10.0.0.6"
            member_name        = "notebooks"
          }
        }
        lock = {
          kind  = "CanNotDelete"
          name  = "endpoint-lock"
          notes = "Keep this endpoint."
        }
        role_assignments = {
          reader = {
            name                                   = "00000000-0000-0000-0000-000000000001"
            role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id                           = "00000000-0000-0000-0000-000000000002"
            description                            = "Endpoint reader."
            principal_type                         = "ServicePrincipal"
            skip_service_principal_aad_check       = true
            condition                              = "!(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'})"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/delegated"
          }
        }
      }
    }
  }
  assert {
    condition     = azurerm_private_endpoint.this["endpoint"].ip_configuration[0].member_name == "notebooks" && toset(azurerm_private_endpoint.this["endpoint"].private_service_connection[0].subresource_names) == toset(["amlworkspace"])
    error_message = "The configured static IP member and subresource must reach the private endpoint."
  }
  assert {
    condition     = azurerm_private_endpoint.this["endpoint"].private_dns_zone_group[0].name == "custom-group" && toset(azurerm_private_endpoint.this["endpoint"].private_dns_zone_group[0].private_dns_zone_ids) == var.private_endpoints["endpoint"].private_dns_zone_resource_ids
    error_message = "Managed DNS must retain the requested zone group and zone IDs."
  }
  assert {
    condition     = azurerm_private_endpoint.this["endpoint"].name == "custom-endpoint" && azurerm_private_endpoint.this["endpoint"].location == "westeurope" && azurerm_private_endpoint.this["endpoint"].resource_group_name == "endpoint-rg" && azurerm_private_endpoint.this["endpoint"].custom_network_interface_name == "endpoint-nic" && azurerm_private_endpoint.this["endpoint"].tags["purpose"] == "unit"
    error_message = "Endpoint names, location, resource group, NIC, and tags must remain configurable."
  }
  assert {
    condition     = azurerm_private_endpoint_application_security_group_association.this["endpoint-clients"].private_endpoint_id == output.private_endpoints["endpoint"].id
    error_message = "The existing application security group association address must scope to the endpoint."
  }
  assert {
    condition     = azurerm_management_lock.private_endpoints["endpoint"].scope == output.private_endpoints["endpoint"].id && azurerm_management_lock.private_endpoints["endpoint"].name == "endpoint-lock" && azurerm_management_lock.private_endpoints["endpoint"].notes == "Keep this endpoint." && azurerm_management_lock.private_endpoints["endpoint"].lock_level == "CanNotDelete"
    error_message = "Endpoint lock settings must no longer be ignored."
  }
  assert {
    condition     = azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].scope == output.private_endpoints["endpoint"].id && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].name == var.private_endpoints["endpoint"].role_assignments["reader"].name && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].principal_id == var.private_endpoints["endpoint"].role_assignments["reader"].principal_id && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].role_definition_id == var.private_endpoints["endpoint"].role_assignments["reader"].role_definition_id_or_name
    error_message = "Endpoint role assignments must preserve the requested name, principal, role, and endpoint scope."
  }
  assert {
    condition     = azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].description == "Endpoint reader." && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].principal_type == "ServicePrincipal" && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].skip_service_principal_aad_check && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].condition_version == "2.0" && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].condition == var.private_endpoints["endpoint"].role_assignments["reader"].condition && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].delegated_managed_identity_resource_id == var.private_endpoints["endpoint"].role_assignments["reader"].delegated_managed_identity_resource_id
    error_message = "Endpoint role assignment metadata and permission conditions must be preserved."
  }
}

run "unmanaged_endpoint_extensions" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/privateDnsZones/privatelink.api.azureml.ms"]
        application_security_group_associations = {
          clients = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/applicationSecurityGroups/clients"
        }
        ip_configurations = {
          notebook = {
            name               = "notebook"
            private_ip_address = "10.0.0.6"
            member_name        = "notebooks"
          }
        }
        lock = {
          kind = "ReadOnly"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000002"
          }
        }
      }
    }
  }
  assert {
    condition     = length(azurerm_private_endpoint.this) == 0 && length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 1 && length(output.private_endpoints) == 1
    error_message = "Unmanaged DNS endpoints must keep their address and appear in outputs."
  }
  assert {
    condition     = length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_dns_zone_group) == 0 && azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration[0].member_name == "notebooks"
    error_message = "Unmanaged DNS must not create a zone group and must honor static IP member names."
  }
  assert {
    condition     = azurerm_private_endpoint_application_security_group_association.this["endpoint-clients"].private_endpoint_id == output.private_endpoints["endpoint"].id && azurerm_management_lock.private_endpoints["endpoint"].scope == output.private_endpoints["endpoint"].id && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].scope == output.private_endpoints["endpoint"].id && azurerm_role_assignment.private_endpoints["[\"endpoint\",\"reader\"]"].role_definition_name == "Reader"
    error_message = "All endpoint extensions must work when DNS management is external."
  }
  assert {
    condition     = azurerm_management_lock.private_endpoints["endpoint"].name == "lock-ReadOnly" && azurerm_management_lock.private_endpoints["endpoint"].notes == "Cannot delete or modify the resource or its child resources."
    error_message = "Omitted endpoint lock names and notes must receive usable defaults."
  }
}

run "hub_endpoint" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    kind = "Hub"
    managed_identities = {
      user_assigned_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/unit-identity"]
    }
    primary_user_assigned_identity = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/unit-identity"
    }
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
      }
    }
  }
  assert {
    condition     = length(azapi_resource.hub) == 1 && length(azapi_resource.this) == 0 && length(azapi_resource.project) == 0 && azurerm_private_endpoint.this["endpoint"].private_service_connection[0].private_connection_resource_id == azapi_resource.hub[0].id
    error_message = "Hub endpoints must target the existing hub resource address."
  }
  assert {
    condition     = azapi_resource.hub[0].identity[0].type == "UserAssigned" && toset(azapi_resource.hub[0].identity[0].identity_ids) == var.managed_identities.user_assigned_resource_ids && azapi_resource.hub[0].body.properties.primaryUserAssignedIdentity == var.primary_user_assigned_identity.resource_id
    error_message = "Hub user-assigned and primary identity semantics must remain unchanged."
  }
}

run "project_endpoint" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    kind = "Project"
    tags = {
      purpose = "project-unit"
    }
    key_vault = {
      resource_id = null
    }
    storage_account = {
      resource_id = null
    }
    azure_ai_hub = {
      resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.MachineLearningServices/workspaces/unit-hub"
    }
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
      }
    }
  }
  assert {
    condition     = length(azapi_resource.project) == 1 && length(azapi_resource.this) == 0 && length(azapi_resource.hub) == 0 && azurerm_private_endpoint.this["endpoint"].private_service_connection[0].private_connection_resource_id == azapi_resource.project[0].id && azapi_resource.project[0].body.properties.hubResourceId == var.azure_ai_hub.resource_id
    error_message = "Project endpoints and hub linkage must retain their existing workspace semantics."
  }
  assert {
    condition     = azapi_resource.project[0].tags["purpose"] == "project-unit"
    error_message = "Projects must receive the caller's tags just like other workspace kinds."
  }
}

run "reject_invalid_subnet" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "not-a-subnet"
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "reject_invalid_dns_zone" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
        private_dns_zone_resource_ids = ["not-a-zone"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "reject_invalid_security_group" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
        application_security_group_associations = {
          clients = "not-a-security-group"
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "reject_invalid_delegated_identity" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/unit-rg/providers/Microsoft.Network/virtualNetworks/unit-vnet/subnets/endpoints"
        role_assignments = {
          reader = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "00000000-0000-0000-0000-000000000002"
            delegated_managed_identity_resource_id = "not-an-identity"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}
