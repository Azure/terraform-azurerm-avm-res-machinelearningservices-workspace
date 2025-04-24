output "resource" {
  description = "The machine learning workspace."
  sensitive   = true
  value       = module.azureml
}
