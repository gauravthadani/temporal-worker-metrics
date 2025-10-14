terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "4.5.3"
    }
  }
}

provider "grafana" {
  # Configuration options
  url  = var.grafana_url
  auth = var.grafana_auth
}