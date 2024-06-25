locals {
  key_vault_name = replace("kv${var.name}", "/[^a-zA-Z0-9-]/", "")
}
