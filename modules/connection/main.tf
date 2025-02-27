resource "azapi_resource" "connection" {
  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-10-01-preview"
  body = {
    properties = {
      category       = var.category
      expiryTime     = var.expiry_time
      isSharedToAll  = var.shared_by_all
      target         = var.target
      sharedUserList = var.shared_user_list
      authType       = var.auth_type
      credentials    = var.credentials
      metadata       = var.metadata
    }
  }
  name                      = var.name
  parent_id                 = var.workspace_id
  schema_validation_enabled = false # authType & credentials have too much variety
  tags                      = var.tags

  lifecycle {
    ignore_changes = [
      tags,                    # tags are occasionally added by Azure
      body.properties.metadata # this is also occasionally modified by Azure
    ]
  }
  ignore_casing = true
}