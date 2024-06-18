locals {
  storage_account_name = replace("sa${var.name}", "/[^a-zA-Z0-9]/", "")
}
