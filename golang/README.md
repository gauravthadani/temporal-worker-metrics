# Temporal Worker Metrics

## Build Docker Images

### Worker

To build the Docker image for the temporal worker:

```bash
docker build --tag=worker -f Dockerfile.worker ./
```

This will create a Docker image tagged as `worker` that contains the temporal worker application with metrics collection capabilities.

Load it into kind:

```bash
kind load docker-image worker:latest
```

### Starter

To build the Docker image for the temporal starter:

```bash
docker build --tag=starter -f Dockerfile.starter ./
```

This will create a Docker image tagged as `starter` that contains the temporal workflow starter application.

Load it into kind:

```bash
kind load docker-image starter:latest
```