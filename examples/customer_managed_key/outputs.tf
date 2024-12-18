output "resource" {
  description = "The output of the module"
  sensitive   = true
  value       = module.azureml
}
