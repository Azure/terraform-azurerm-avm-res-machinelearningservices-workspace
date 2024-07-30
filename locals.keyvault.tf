locals {
  key_vault_id   = var.key_vault.resource_id == null ? replace(module.avm_res_keyvault_vault[0].resource_id, "Microsoft.KeyVault", "Microsoft.Keyvault") : var.key_vault.resource_id
  key_vault_name = replace("kv${var.name}", "/[^a-zA-Z0-9-]/", "")
}

 