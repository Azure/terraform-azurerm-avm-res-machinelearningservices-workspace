locals {
  parsed_name     = try(local.parsed_resource.name, var.name, null)
  parsed_resource = provider::azapi::parse_resource_id(local.resource_type, local.resource_id)
  resource_id     = azapi_resource.connection.id
  resource_type   = "Microsoft.MachineLearningServices/workspaces/connections"
}
