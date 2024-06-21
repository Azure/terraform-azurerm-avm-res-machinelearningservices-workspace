locals {
  container_registry_name = replace("acr${var.name}", "/[^a-zA-Z0-9]/", "")
}
