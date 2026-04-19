#!/bin/bash
set -e

echo "🚀 Starting Temporal Worker Metrics Bootstrap"

# Check if API key files exist
API_KEY_FILE="temporal-certs/api_key"
API_KEY_FILE_METRICS="temporal-certs/api_key_metrics"
for f in "$API_KEY_FILE" "$API_KEY_FILE_METRICS"; do
    if [ ! -f "$f" ]; then
        echo "❌ Error: API key file not found at $f"
        exit 1
    fi
done

# Read API keys
API_KEY=$(cat "$API_KEY_FILE")
echo "✅ API key loaded from $API_KEY_FILE"
API_KEY_METRICS=$(cat "$API_KEY_FILE_METRICS")
echo "✅ API key loaded from $API_KEY_FILE_METRICS"

# Start local pull-through registry (persists across kind restarts)
if ! docker inspect kind-registry &>/dev/null; then
    echo "📦 Starting local registry cache..."
    docker run -d --restart=always -p 5001:5000 \
        -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
        --name kind-registry registry:2
    echo "✅ Registry started"
else
    echo "✅ Registry already running"
fi

# Create kind cluster
echo "📦 Creating kind cluster..."
kind create cluster --config kind-config.yaml
echo "✅ Kind cluster created"

# Connect registry to kind network so nodes can reach it
docker network connect kind kind-registry 2>/dev/null || true
echo "✅ Registry connected to kind network"

# Install KEDA
echo "⚙️  Installing KEDA..."
[ -f charts/keda-2.19.0.tgz ] || helm pull kedacore/keda --version 2.19.0 -d charts/
helm install keda charts/keda-2.19.0.tgz \
    --namespace keda \
    --create-namespace \
    --wait
echo "✅ KEDA installed"

# Create API key secret
echo "🔑 Creating Temporal API key secret..."
kubectl create secret generic temporal-api-key \
    --from-literal=api_key="$API_KEY" \
    --namespace default \
    --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Secret created"

# Create Prometheus API key secret
echo "🔑 Creating Prometheus API key secret..."
kubectl create secret generic temporal-api-key-metrics \
    --from-literal=api_key="$API_KEY_METRICS" \
    --namespace default \
    --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Secret created"

# Create mTLS secret for Temporal Cloud
echo "🔑 Creating Temporal mTLS secret..."
kubectl create secret generic temporal-mtls \
    --from-file=client.pem=temporal-certs/client.pem \
    --from-file=client.key=temporal-certs/client.key \
    --namespace default \
    --dry-run=client -o yaml | kubectl apply -f -
echo "✅ mTLS secret created"

# Install infra chart (temporal, prometheus, grafana)
echo "📦 Installing infra chart..."
helm install temporal helm/temporal \
    --namespace default \
    --wait
echo "✅ Infra chart installed"

echo "⏳ Waiting for Temporal to be ready..."
kubectl rollout status deployment/temporal -n default --timeout=120s
echo "✅ Temporal is ready"

echo "⏳ Waiting for Prometheus to be ready..."
kubectl rollout status deployment/prometheus -n default --timeout=120s
echo "✅ Prometheus is ready"

echo "⏳ Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n default --timeout=120s
echo "✅ Grafana is ready"

# Deploy app with Skaffold (builds images, deploys temporal-worker-metrics chart)
echo "⚙️  Deploying with Skaffold..."
skaffold run
echo "✅ Skaffold deployment complete"

# Deploy Grafana dashboards with Terraform
echo "📊 Deploying Grafana dashboards..."
cd auto
terraform apply -var-file=k8s.tfvars -auto-approve
cd ..
echo "✅ Dashboards deployed"

# Show deployment status
echo ""
echo "📊 Deployment Status:"
kubectl get pods -n default
echo ""
echo "🌐 Access URLs:"
echo "  - Grafana:    http://localhost:30030 (admin/admin)"
echo "  - Prometheus: http://localhost:30090"
echo "  - Temporal:   http://localhost:30233"
echo ""

# Ask user if they want to launch starters
echo "🚦 Should we launch starters? This will create workflow load."
read -p "Launch starters? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Launching starters..."
    skaffold run -p starters
    echo "✅ Starters launched"
else
    echo "⏸️  Starters not launched. You can manually start them later with:"
    echo "   skaffold run -p starters"
fi

echo ""
echo "✨ Bootstrap complete!"
