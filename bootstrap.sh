#!/bin/bash
set -e

echo "🚀 Starting Temporal Worker Metrics Bootstrap"

# Check if API key file exists
API_KEY_FILE="temporal-certs/api_key_metrics"
if [ ! -f "$API_KEY_FILE" ]; then
    echo "❌ Error: API key file not found at $API_KEY_FILE"
    echo "Please create the file with your Temporal Cloud API key"
    exit 1
fi

# Read API key
API_KEY=$(cat "$API_KEY_FILE")
echo "✅ API key loaded from $API_KEY_FILE"

# Create kind cluster
echo "📦 Creating kind cluster..."
kind create cluster --config kind-config.yaml
echo "✅ Kind cluster created"

# Build Docker images
echo "🔨 Building Docker images..."
docker build -t worker:latest -f golang/Dockerfile.worker golang/
docker build -t starter:latest -f golang/Dockerfile.starter golang/
echo "✅ Docker images built"

# Load images into kind
echo "📤 Loading images into kind cluster..."
kind load docker-image worker:latest
kind load docker-image starter:latest
echo "✅ Images loaded into kind"

# Deploy with Helm (without starters initially)
echo "⚙️  Deploying with Helm..."
helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics \
    --namespace default \
    --set-string prometheus.apiKey="$API_KEY" \
    --set starter.enabled=false
echo "✅ Helm deployment complete"

# Wait for prometheus to be ready
echo "⏳ Waiting for Prometheus to be ready..."
kubectl rollout status deployment/prometheus -n default --timeout=120s
echo "✅ Prometheus is ready"

# Wait for Grafana to be ready
echo "⏳ Waiting for Grafana to be ready..."
kubectl rollout status deployment/grafana -n default --timeout=120s
echo "✅ Grafana is ready"

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
echo "🚦 Should we launch 100 starters? This will create workflow load."
read -p "Launch starters? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Launching starters..."
    helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics \
        --namespace default \
        --set-string prometheus.apiKey="$API_KEY" \
        --set starter.enabled=true
    echo "✅ Starters launched"
else
    echo "⏸️  Starters not launched. You can manually start them later with:"
    echo "   helm upgrade --install temporal-worker-metrics ./helm/temporal-worker-metrics --namespace default --set-string prometheus.apiKey=\"\$(cat temporal-certs/api_key_metrics)\" --set starter.enabled=true"
fi

echo ""
echo "✨ Bootstrap complete!"
