output "resource" {
  description = "The AI Studio hub workspace."
  sensitive   = true
  value       = module.aihub
}
