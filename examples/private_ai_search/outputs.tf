output "resource" {
  description = "Relevant properties of the machine learning workspace and supporting resources."
  sensitive   = true
  value       = module.azureml
}
