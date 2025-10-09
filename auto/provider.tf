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
  url  = "http://localhost:3000"
  auth = "admin:admin"
}