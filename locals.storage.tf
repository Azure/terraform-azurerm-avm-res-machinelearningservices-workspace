locals {
  storage_account_id   = var.storage_account.resource_id == null ? module.avm_res_storage_storageaccount[0].resource_id : var.storage_account.resource_id
  storage_account_name = replace("sa${var.name}", "/[^a-zA-Z0-9]/", "")
}
