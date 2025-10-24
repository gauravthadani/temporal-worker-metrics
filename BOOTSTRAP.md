# Temporal Worker Metrics - Bootstrap Guide

This guide will help you set up and deploy the Temporal worker metrics project from scratch.

## Prerequisites

- Docker
- kind (Kubernetes in Docker)
- kubectl
- helm
- Go 1.25.0+

## Quick Start

### 1. Create kind Cluster with Port Mappings

The kind cluster needs to be created with port mappings to access services from localhost:

```bash
kind create cluster --config kind-config.yaml
```

This exposes:
- **Grafana**: `localhost:30030`
- **Prometheus**: `localhost:30090`
- **Temporal UI**: `localhost:30233`

### 2. Build Docker Images

Build both the worker and starter images:

```bash
docker build -t worker:latest -f golang/Dockerfile.worker golang/
docker build -t starter:latest -f golang/Dockerfile.starter golang/
```

### 3. Load Images into kind

Load the built images into the kind cluster:

```bash
kind load docker-image worker:latest
kind load docker-image starter:latest
```

### 4. Deploy with Helm

Deploy all services using Helm:

```bash
helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics --namespace default
```

### 5. Verify Deployment

Check that all pods are running:

```bash
kubectl get pods -n default
kubectl get svc -n default
```

Expected pods:
- `temporal-*` - Temporal server
- `worker-*` - Temporal worker with metrics
- `starter-*` - Job starter pods (100 by default)
- `prometheus-*` - Prometheus metrics collector
- `grafana-*` - Grafana dashboard

## Accessing Services

### Grafana
- URL: `http://localhost:30030`
- Username: `admin`
- Password: `admin`
- Datasource: Prometheus (pre-configured)

### Prometheus
- URL: `http://localhost:30090`
- Scrapes metrics from worker on port 8079

### Temporal UI
- URL: `http://localhost:30233`

### Temporal gRPC (optional)
If you need direct gRPC access to Temporal on a custom port:

```bash
kubectl port-forward svc/temporal 37233:7233 -n default
```

Then connect to `localhost:37233`

## Configuration

### Adjust Starter Jobs

To change the number of workflow starters, edit `helm/temporal-worker-metrics/values.yaml`:

```yaml
starter:
  completions: 100    # Total number of jobs to run
  parallelism: 100    # Number of jobs to run in parallel
```

Then upgrade the deployment:

```bash
helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics --namespace default
```

### Worker Scaling

To scale the worker deployment:

```bash
kubectl scale deployment worker --replicas=5 -n default
```

Or edit `values.yaml`:

```yaml
worker:
  replicas: 5
```

## Metrics

The worker exposes Prometheus metrics on port 8079:

### Key Metrics
- `temporal_worker_task_slots_available` - Available task slots
- `temporal_worker_task_slots_used` - Used task slots
- `schedule_to_start_latency` - Time from activity schedule to start
- `activity_latency` - Activity execution time
- `temporal_activity_poll_no_task_total` - Polling with no tasks

### Viewing Metrics

Access Prometheus at `http://localhost:30090` and query:

```promql
# View schedule to start latency
rate(schedule_to_start_latency_bucket[1m])

# View task slot usage
temporal_worker_task_slots_used

# View available slots
temporal_worker_task_slots_available
```

## Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod <pod-name> -n default
kubectl logs <pod-name> -n default
```

### Rebuild and Redeploy Everything
```bash
# Delete cluster
kind delete cluster

# Create new cluster
kind create cluster --config kind-config.yaml

# Build images
docker build -t worker:latest -f golang/Dockerfile.worker golang/
docker build -t starter:latest -f golang/Dockerfile.starter golang/

# Load images
kind load docker-image worker:latest
kind load docker-image starter:latest

# Deploy
helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics --namespace default
```

### Check Worker Metrics Endpoint
```bash
kubectl port-forward svc/worker 8079:8079 -n default
curl http://localhost:8079/metrics
```

### Delete and Restart Starter Jobs
```bash
kubectl delete job starter -n default
helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics --namespace default
```

## Architecture

```
┌─────────────┐
│   Starter   │ (Job: 100 completions, 100 parallelism)
│   Pods      │ ──> Submits workflows to Temporal
└─────────────┘

┌─────────────┐
│  Temporal   │ (Server on port 7233, UI on 8233)
│   Server    │ ──> Orchestrates workflows
└─────────────┘

┌─────────────┐
│   Worker    │ (Exposes metrics on port 8079)
│    Pods     │ ──> Executes activities, emits metrics
└─────────────┘

┌─────────────┐
│ Prometheus  │ (Scrapes port 8079, accessible on 30090)
│             │ ──> Collects metrics from worker
└─────────────┘

┌─────────────┐
│  Grafana    │ (Accessible on port 30030)
│             │ ──> Visualizes metrics from Prometheus
└─────────────┘
```

## Cleanup

Delete the entire cluster:

```bash
kind delete cluster
```

Delete just the Helm release:

```bash
helm uninstall temporal-worker-metrics -n default
```
