#!/bin/bash
set -e

echo "🚀 Starting Temporal Worker Metrics Bootstrap"

# Ask which language stack to deploy
echo ""
echo "Which worker stack would you like to deploy?"
echo "  1) Go    (skaffold.yaml)"
echo "  2) Java  (skaffold-java.yaml)"
read -p "Choice [1/2]: " -n 1 -r LANG_CHOICE
echo ""
case "$LANG_CHOICE" in
    1|g|G)
        SKAFFOLD_FILE="skaffold.yaml"
        LANG_LABEL="Go"
        ;;
    2|j|J)
        SKAFFOLD_FILE="skaffold-java.yaml"
        LANG_LABEL="Java"
        ;;
    *)
        echo "❌ Invalid choice '$LANG_CHOICE'. Expected 1 or 2."
        exit 1
        ;;
esac
echo "✅ Selected $LANG_LABEL stack ($SKAFFOLD_FILE)"
echo ""

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

# Pre-pull helm charts if not cached
mkdir -p charts
[ -f charts/cert-manager-1.20.2.tgz ] || \
    helm pull oci://quay.io/jetstack/charts/cert-manager --version 1.20.2 -d charts/
[ -f charts/temporal-worker-controller-crds-0.26.0.tgz ] || \
    helm pull oci://docker.io/temporalio/temporal-worker-controller-crds --version 0.26.0 -d charts/
[ -f charts/temporal-proxy-0.2.0.tgz ] || \
    helm pull temporal-proxy --repo https://go.temporal.io/helm-charts --version 0.2.0 -d charts/

# Install cert-manager
echo "🔐 Installing cert-manager..."
helm install cert-manager charts/cert-manager-1.20.2.tgz \
    --namespace cert-manager \
    --create-namespace \
    --set crds.enabled=true \
    --wait
echo "✅ cert-manager installed"

# Install temporal-worker-controller CRDs
echo "⚙️  Installing temporal-worker-controller CRDs..."
helm install temporal-worker-controller-crds \
    charts/temporal-worker-controller-crds-0.26.0.tgz \
    --namespace default
echo "✅ temporal-worker-controller CRDs installed"

# Create Prometheus API key secret
echo "🔑 Creating Prometheus API key secret..."
kubectl create secret generic temporal-api-key \
    --from-literal=api_key="$API_KEY" \
    --namespace default \
    --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Secret created"

# Fetch helm chart dependencies (must be run from helm/temporal/)
echo "📦 Fetching helm chart dependencies..."
(cd helm/temporal && helm dependency build)
echo "✅ Helm dependencies fetched"

# Install infra chart (temporal, prometheus, grafana, temporal-worker-controller)
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

# Create temporal-proxy API key secret (for cloud upstream)
PROXY_API_KEY_FILE="temporal-certs/api_key"
if [ ! -f "$PROXY_API_KEY_FILE" ]; then
    echo "❌ Error: temporal-proxy API key file not found at $PROXY_API_KEY_FILE"
    exit 1
fi
PROXY_API_KEY=$(cat "$PROXY_API_KEY_FILE")
kubectl create secret generic temporal-proxy-api-key \
    --from-literal=api_key="$PROXY_API_KEY" \
    --namespace default \
    --dry-run=client -o yaml | kubectl apply -f -
echo "✅ temporal-proxy API key secret created"

# Install temporal-proxy
echo "🔀 Installing temporal-proxy..."
helm install temporal-proxy charts/temporal-proxy-0.2.0.tgz \
    --namespace default \
    -f helm/proxy/values.yaml \
    --wait
echo "✅ temporal-proxy installed"

# Install proxy Connection CR
echo "🔗 Installing proxy Connection CR..."
helm install proxy helm/proxy --namespace default
echo "✅ proxy Connection installed"

# Deploy app with Skaffold (builds images, deploys temporal-worker-metrics chart)
echo "⚙️  Deploying $LANG_LABEL worker with Skaffold ($SKAFFOLD_FILE)..."
skaffold run -f "$SKAFFOLD_FILE"
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
    echo "🚀 Launching $LANG_LABEL starters..."
    skaffold run -f "$SKAFFOLD_FILE" -p starters
    echo "✅ Starters launched"
else
    echo "⏸️  Starters not launched. You can manually start them later with:"
    echo "   skaffold run -f $SKAFFOLD_FILE -p starters"
fi

echo ""
echo "✨ Bootstrap complete!"
