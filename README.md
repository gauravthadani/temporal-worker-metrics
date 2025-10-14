# Temporal Worker Metrics

This project demonstrates how to integrate Prometheus metrics with Temporal workflows and activities in Go.

## Overview

The sample shows how to:
- Set up Prometheus metrics collection for Temporal workers
- Record activity execution metrics (latency, success/failure counts)
- Export metrics via HTTP endpoint for Prometheus scraping
- Track schedule-to-start latency for activities

## Prerequisites

1. Go 1.19+
2. Running [Temporal service](https://github.com/temporalio/samples-go/tree/main/#how-to-use)

## Quick Start

1. **Start Temporal**

   ```bash
   temporal server start-dev
   ```

2. **Bring up services**

   ```bash
   docker compose up -d
   ```

3. **Start the worker with metrics collection:**

   ```bash
   go run worker/main.go
   ```

4. **Execute a workflow to generate metrics:**

   ```bash
   go run starter/main.go
   ```

5. **View metrics:**
   - Prometheus endpoint: http://localhost:8079/metrics
   - Metrics are scraped by Prometheus from this endpoint

## Configuration

### API Key Authentication
Set your Temporal Cloud API key:
```bash
export TEMPORAL_CLIENT_API_KEY=your_api_key_here
```

Or pass via command line:
```bash
go run worker/main.go -api-key your_api_key_here
```

### Command Line Options
- `-target-host`: Temporal server host:port (default: localhost:7233)
- `-namespace`: Temporal namespace (default: default)
- `-api-key`: API key for authentication

## Terraform - Grafana Dashboard Provisioning

The `auto/` directory contains Terraform configuration to automatically provision Grafana dashboards.

### Environments

Two environment configurations are available:

1. **local.tfvars** - For docker-compose environment (Grafana on localhost:3000)
2. **k8s.tfvars** - For Kubernetes environment (Grafana service discovery)

### Usage

For docker-compose:
```bash
cd auto
terraform init
terraform apply -var-file=local.tfvars
```

For Kubernetes:
```bash
cd auto
terraform init
terraform apply -var-file=k8s.tfvars
```

This will:
- Create Prometheus data sources in Grafana
- Provision all dashboards from the `dashboards/` directory
- Create a "Temporal Dashboards" folder

## Kubernetes Deployment

### Setup Kind Cluster

The `kind-config.yaml` configures port mappings for accessing services:

```bash
kind create cluster --config kind-config.yaml
```

This exposes:
- **Grafana**: http://localhost:30030
- **Prometheus**: http://localhost:30090
- **Temporal**: http://localhost:30233

### Deploy to Kind

```bash
# Build images
cd golang
docker build -f Dockerfile.worker -t worker:latest .
docker build -f Dockerfile.starter -t starter:latest .

# Load into Kind
kind load docker-image worker:latest --name kind
kind load docker-image starter:latest --name kind

# Deploy with Helm
helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics
```

The starter is configured as a Kubernetes Job that runs once with configurable parallelism (default: 1).

## Dashboard Management

Add dashboards by placing JSON files in the `dashboards/` directory. Terraform will automatically discover and provision them.

Dashboard subtree:
```bash
git subtree add --prefix=dashboards https://github.com/temporalio/dashboards.git master --squash
```