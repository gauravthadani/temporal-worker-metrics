# Temporal Worker Metrics — KEDA Autoscaling

Autoscales Temporal workers on Kubernetes using [KEDA](https://keda.sh/), with Prometheus metrics and Grafana dashboards. Workers connect to Temporal Cloud via API key or mTLS.

## Prerequisites

- Docker, kind, kubectl, Helm v3, Skaffold, Terraform, Go 1.23+

Place the following files in `temporal-certs/` before running:

| File | Purpose |
|---|---|
| `temporal-certs/api_key` | API key for the worker to connect to Temporal Cloud |
| `temporal-certs/api_key_metrics` | API key for Prometheus to scrape Temporal Cloud metrics |
| `temporal-certs/client.pem` + `client.key` | mTLS cert/key _(if using mTLS instead of API key)_ |

## Quick Start

```bash
./bootstrap.sh
```

Bootstrap handles everything: kind cluster, KEDA, secrets, infra (Prometheus + Grafana), worker deployment, and Grafana dashboards.

Access:
- **Grafana**: http://localhost:30030 (admin/admin)
- **Prometheus**: http://localhost:30090
- **Temporal UI**: http://localhost:30233

## Launch workflow load

```bash
skaffold run -p starters
```

## Configuration

Worker and KEDA settings (min/max replicas, target queue size, namespace, auth) are in `helm/worker/values.yaml`.
