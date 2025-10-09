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
git subtree add --prefix=dashboards https://github.com/temporalio/dashboards.git master --squash


Add new panel 
```

sum(rate(temporal_request_resource_exhausted_total{namespace=~"$namespace", namespace!="none"}[$__rate_interval])) by (namespace, operation, task_queue)

```