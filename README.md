# Temporal Worker Metrics

This project demonstrates how to run Temporal workers on Kubernetes with Prometheus metrics, Grafana dashboards, and automated versioned rollouts via the [temporal-worker-controller](https://github.com/temporalio/temporal-worker-controller).

## Overview

- Temporal Go worker with Prometheus metrics (tally/histogram)
- Resource-based tuner + poller autoscaling
- Worker versioning via `TemporalWorkerDeployment` (AllAtOnce rollout)
- Prometheus scraping worker metrics + Temporal Cloud metrics
- Grafana dashboards provisioned via Terraform

## Prerequisites

- [Go 1.23+](https://go.dev)
- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm v3](https://helm.sh/)
- [Skaffold](https://skaffold.dev/)
- [Terraform](https://www.terraform.io/)
- Temporal Cloud metrics API key in `temporal-certs/api_key_metrics`

## Quick Start

```bash
./bootstrap.sh
```

This will:
1. Create a local kind cluster
2. Create the Prometheus API key secret in k8s
3. Fetch Helm chart dependencies (`helm dependency build` from `helm/temporal/`)
4. Build worker + starter images and deploy everything via Skaffold (including the temporal-worker-controller)
5. Provision Grafana dashboards via Terraform
6. Optionally launch workflow load

Access:
- **Grafana**: http://localhost:30030 (admin/admin)
- **Prometheus**: http://localhost:30090
- **Temporal UI**: http://localhost:30233

## Architecture

```
WorkerDeployment
  └─ managed by temporal-worker-controller
       └─ creates/manages Deployment pods (versioned)
            └─ worker exposes :8079/metrics
                 └─ scraped by Prometheus → Grafana
```

The worker reads `TEMPORAL_WORKER_BUILD_ID` and `TEMPORAL_DEPLOYMENT_NAME` injected by the controller and enables worker versioning automatically. When running locally without the controller these env vars are absent and versioning is skipped.

## Development

### Helm dependencies

The `helm/temporal` chart depends on `temporal-worker-controller` via OCI. Run the build from inside that directory — running it from the project root will fail with a misleading file-size error:

```bash
cd helm/temporal && helm dependency build
```

### Iterating with Skaffold

```bash
# Build, push to kind, and deploy (one-shot)
skaffold run

# Continuous dev loop with file watching
skaffold dev
```

### Launch workflow load

```bash
skaffold run --set-value starter.enabled=true
```

### Run worker locally (no k8s)

```bash
cd golang
go run prometheus/worker/main.go -target-host=localhost:7233
```

## Terraform — Grafana Dashboards

```bash
cd auto

# local docker-compose
terraform apply -var-file=local.tfvars

# kind / k8s
terraform apply -var-file=k8s.tfvars
```

## Dashboard subtree

```bash
git subtree add --prefix=dashboards https://github.com/temporalio/dashboards.git master --squash
git subtree pull --prefix=dashboards https://github.com/temporalio/dashboards.git master --squash
```
