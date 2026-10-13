resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = local.aml_resource.id
    subresource_names              = [coalesce(each.value.subresource_name, "amlworkspace")]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = coalesce(ip_configuration.value.member_name, "default")
      subresource_name   = coalesce(each.value.subresource_name, "amlworkspace")
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? ["this"] : []

    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }
}

# The PE resource when we are managing **not** the private_dns_zone_group block:
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  location                      = each.value.location != null ? each.value.location : var.location
  name                          = each.value.name != null ? each.value.name : "pep-${var.name}"
  resource_group_name           = each.value.resource_group_name != null ? each.value.resource_group_name : var.resource_group_name
  subnet_id                     = each.value.subnet_resource_id
  custom_network_interface_name = each.value.network_interface_name
  tags                          = each.value.tags

  private_service_connection {
    is_manual_connection           = false
    name                           = each.value.private_service_connection_name != null ? each.value.private_service_connection_name : "pse-${var.name}"
    private_connection_resource_id = local.aml_resource.id
    subresource_names              = [coalesce(each.value.subresource_name, "amlworkspace")]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations

    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      member_name        = coalesce(ip_configuration.value.member_name, "default")
      subresource_name   = coalesce(each.value.subresource_name, "amlworkspace")
    }
  }

  lifecycle {
    ignore_changes = [private_dns_zone_group]
  }
}

resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = local.private_endpoint_application_security_group_associations

  application_security_group_id = each.value.asg_resource_id
  private_endpoint_id           = local.private_endpoints[each.value.pe_key].id
}

data "azapi_resource_list" "private_endpoint_role_definitions" {
  for_each = { for k, v in local.private_endpoint_role_assignments : k => v if !strcontains(lower(v.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) }

  parent_id = local.private_endpoints[each.value.pe_key].id
  type      = "Microsoft.Authorization/roleDefinitions@2022-04-01"
  response_export_values = {
    results = "value[].{id: id, role_name: properties.roleName}"
  }
}

resource "random_uuid" "private_endpoint_role_assignment_name" {
  for_each = local.private_endpoint_role_assignments
}

resource "azapi_resource" "private_endpoint_role_assignments" {
  for_each = local.private_endpoint_role_assignments

  name      = coalesce(each.value.role_assignment.name, random_uuid.private_endpoint_role_assignment_name[each.key].result)
  parent_id = local.private_endpoints[each.value.pe_key].id
  type      = var.resource_types.authorization_role_assignments
  body = {
    properties = {
      principalId                        = each.value.role_assignment.principal_id
      roleDefinitionId                   = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_assignment.role_definition_id_or_name : one([for definition in data.azapi_resource_list.private_endpoint_role_definitions[each.key].output.results : definition.id if definition.role_name == each.value.role_assignment.role_definition_id_or_name])
      conditionVersion                   = each.value.role_assignment.condition_version
      condition                          = each.value.role_assignment.condition
      description                        = each.value.role_assignment.description
      principalType                      = each.value.role_assignment.principal_type
      delegatedManagedIdentityResourceId = each.value.role_assignment.delegated_managed_identity_resource_id
    }
  }
  ignore_body_changes = length(var.ignore_body_changes.authorization_role_assignments) > 0 ? var.ignore_body_changes.authorization_role_assignments : null
  replace_triggers_refs = [
    "properties.principalId",
    "properties.roleDefinitionId",
    "properties.delegatedManagedIdentityResourceId",
  ]
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = strcontains(lower(each.value.role_assignment.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? true : length([for definition in data.azapi_resource_list.private_endpoint_role_definitions[each.key].output.results : definition.id if definition.role_name == each.value.role_assignment.role_definition_id_or_name]) == 1
      error_message = "The endpoint role definition name must resolve to exactly one role definition at the endpoint scope."
    }
  }
}

resource "azapi_resource" "private_endpoint_locks" {
  for_each = { for k, v in var.private_endpoints : k => v.lock if v.lock != null }

  name      = coalesce(each.value.name, "lock-${each.value.kind}")
  parent_id = local.private_endpoints[each.key].id
  type      = var.resource_types.authorization_locks
  body = {
    properties = {
      level = each.value.kind
      notes = each.value.notes != null ? each.value.notes : each.value.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
    }
  }
  ignore_body_changes    = length(var.ignore_body_changes.authorization_locks) > 0 ? var.ignore_body_changes.authorization_locks : null
  response_export_values = []
  retry                  = var.retry

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      read   = timeouts.value.read
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  depends_on = [
    azurerm_private_endpoint_application_security_group_association.this,
    azapi_resource.private_endpoint_role_assignments,
  ]
}
