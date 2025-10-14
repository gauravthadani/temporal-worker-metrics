variable "environment" {
  description = "Environment type: docker-compose or k8s"
  type        = string
  default     = "docker-compose"

  validation {
    condition     = contains(["docker-compose", "k8s"], var.environment)
    error_message = "Environment must be either 'docker-compose' or 'k8s'."
  }
}

variable "grafana_url" {
  description = "Grafana URL (overrides default based on environment)"
  type        = string
  default     = ""
}

variable "grafana_auth" {
  description = "Grafana authentication (overrides default)"
  type        = string
  default     = "admin:admin"
}

variable "prometheus_url" {
  description = "Prometheus URL (overrides default based on environment)"
  type        = string
  default     = ""
}
