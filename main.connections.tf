module "connections" {
  source = "./modules/connection"

  for_each = var.workspace_connections

  category         = each.value.category
  expiry_time      = each.value.expiry_time
  credentials      = each.value.credentials
  shared_by_all    = each.value.shared_by_all
  target           = each.value.target
  shared_user_list = each.value.shared_user_list
  auth_type        = each.value.auth_type
  metadata         = each.value.metadata
  name             = coalesce(each.value.name, "${local.aml_resource.name}${each.value.category}")
  workspace_id     = local.aml_resource.id
  tags             = coalesce(each.value.tags, var.tags, {})
}