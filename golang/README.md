# Temporal Worker Metrics — Go

Go implementation of a Temporal worker with Prometheus metrics, resource-based tuning, and worker versioning support.

## Running locally

```bash
# Start Temporal dev server
temporal server start-dev

# Run the worker
go run prometheus/worker/main.go -target-host=localhost:7233

# Start a workflow
go run prometheus/starter/main.go -target-host=localhost:7233
```

Metrics are exposed at http://localhost:8079/metrics.

## Worker versioning

When deployed via the [temporal-worker-controller](https://github.com/temporalio/temporal-worker-controller), the controller injects `TEMPORAL_WORKER_BUILD_ID` and `TEMPORAL_DEPLOYMENT_NAME` into the pod. The worker picks these up automatically and enables versioning. No code change needed when updating — just push a new image.

When running locally without those env vars, versioning is skipped and the worker behaves as unversioned.

## Building Docker images

Images are built and loaded into kind automatically by Skaffold. Run `skaffold run` from the repo root.
