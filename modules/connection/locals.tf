locals {
  resource_type   = "Microsoft.MachineLearningServices/workspaces/connections"
  resource_id     = azapi_resource.connection.id
  parsed_resource = provider::azapi::parse_resource_id(local.resource_type, local.resource_id)
  parsed_name     = try(local.parsed_resource.name, var.name, null)
}
