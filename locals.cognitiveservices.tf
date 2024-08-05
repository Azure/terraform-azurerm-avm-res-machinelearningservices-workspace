locals {
  cognitive_services_name = replace("aiservices${var.name}", "/[^a-zA-Z0-9]/", "")
}
