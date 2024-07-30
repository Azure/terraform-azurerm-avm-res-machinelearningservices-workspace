locals {
  container_registry_id   = var.container_registry.resource_id == null ? module.avm_res_containerregistry_registry[0].resource_id : var.container_registry.resource_id
  container_registry_name = replace("acr${var.name}", "/[^a-zA-Z0-9]/", "")
}
