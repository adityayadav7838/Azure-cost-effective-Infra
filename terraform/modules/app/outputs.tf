output "app_service_name" {
  description = "Name of the Kubernetes ClusterIP service for the sample application."
  value       = kubernetes_service.app.metadata[0].name
}

output "app_ingress_hostname" {
  description = "Hostname configured on the Traefik Ingress resource."
  value       = var.application_hostname
}
