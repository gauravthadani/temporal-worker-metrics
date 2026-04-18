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

# Install cert-manager
echo "🔐 Installing cert-manager..."
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
    --version 1.20.2 \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true \
    --wait
echo "✅ cert-manager installed"

# Install temporal-worker-controller
echo "⚙️  Installing temporal-worker-controller..."
helm install temporal-worker-controller-crds \
    oci://docker.io/temporalio/temporal-worker-controller-crds \
    --version 0.24.1 \
    --namespace default
helm install temporal-worker-controller \
    oci://docker.io/temporalio/temporal-worker-controller \
    --version 0.24.1 \
    --namespace default \
    --wait
echo "✅ temporal-worker-controller installed"

# Create Prometheus API key secret
echo "🔑 Creating Prometheus API key secret..."
kubectl create secret generic temporal-api-key \
    --from-literal=api_key="$API_KEY" \
    --namespace default \
    --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Secret created"

# Deploy app with Skaffold (builds images, deploys temporal-worker-metrics chart)
echo "⚙️  Deploying with Skaffold..."
skaffold run
echo "✅ Skaffold deployment complete"

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
    skaffold run --set-value starter.enabled=true
    echo "✅ Starters launched"
else
    echo "⏸️  Starters not launched. You can manually start them later with:"
    echo "   skaffold run --set-value starter.enabled=true"
fi

echo ""
echo "✨ Bootstrap complete!"
