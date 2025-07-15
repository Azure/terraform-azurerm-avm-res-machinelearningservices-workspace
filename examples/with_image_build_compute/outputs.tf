output "resource_id" {
  description = "The ID of the Azure Machine Learning workspace."
  value       = module.azureml.resource_id
}

output "workspace" {
  description = "The Azure Machine Learning workspace details."
  value       = module.azureml.workspace
}

output "image_build_compute_name" {
  description = "The name of the compute cluster configured for image building."
  value       = var.image_build_compute_name
}