#!/bin/bash

# RapidTriageME Production Deployment Script
# Automated deployment to Google Cloud Run (recommended)

set -e

echo "🚀 RapidTriageME Production Deployment"
echo "======================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-rapidtriage-mcp-1754768171}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="rapidtriage-backend"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI not installed${NC}"
    echo "Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker not installed${NC}"
    exit 1
fi

# Step 1: Build Docker image
echo -e "${YELLOW}Step 1: Building Docker image for amd64 platform...${NC}"
cd rapidtriage-server
docker buildx build --platform linux/amd64 -t $IMAGE_NAME:latest --load .
echo -e "${GREEN}✅ Docker image built${NC}"

# Step 2: Configure Docker for GCR
echo -e "${YELLOW}Step 2: Configuring Docker for Google Container Registry...${NC}"
gcloud auth configure-docker
echo -e "${GREEN}✅ Docker configured${NC}"

# Step 3: Push image to GCR
echo -e "${YELLOW}Step 3: Pushing image to Container Registry...${NC}"
docker push $IMAGE_NAME:latest
echo -e "${GREEN}✅ Image pushed to GCR${NC}"

# Step 4: Deploy to Cloud Run
echo -e "${YELLOW}Step 4: Deploying to Cloud Run...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME:latest \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --memory 2Gi \
    --cpu 2 \
    --timeout 60 \
    --max-instances 10 \
    --min-instances 1 \
    --port 3025 \
    --set-env-vars "NODE_ENV=production"

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
    --region $REGION \
    --format 'value(status.url)')

echo -e "${GREEN}✅ Backend deployed to: $SERVICE_URL${NC}"

# Step 5: Update Cloudflare Worker
echo -e "${YELLOW}Step 5: Updating Cloudflare Worker with backend URL...${NC}"
cd ..
echo $SERVICE_URL | wrangler secret put BACKEND_URL --env production
echo -e "${GREEN}✅ Cloudflare Worker updated${NC}"

# Step 6: Test deployment
echo -e "${YELLOW}Step 6: Testing deployment...${NC}"
sleep 5

# Test backend health
echo "Testing backend health..."
BACKEND_HEALTH=$(curl -s $SERVICE_URL/health | jq -r '.status' || echo "failed")
if [ "$BACKEND_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
fi

#Step 7: Test Worker health
echo "Testing Worker health..."
WORKER_HEALTH=$(curl -s https://rapidtriage.me/health | jq -r '.status' || echo "failed")
if [ "$WORKER_HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✅ Worker is healthy${NC}"
else
    echo -e "${RED}❌ Worker health check failed${NC}"
fi

# Step 8: Test MCP endpoint
echo "Testing MCP endpoint..."
MCP_TEST=$(curl -s -X POST https://rapidtriage.me/mcp \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer KskHe6x5tkS4CgLrwfeZvbXsSDmZUjR8" \
    -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' | \
    jq -r '.result.tools[0].name' 2>/dev/null || echo "failed")

if [ "$MCP_TEST" != "failed" ]; then
    echo -e "${GREEN}✅ MCP endpoint is working${NC}"
else
    echo -e "${YELLOW}⚠️ MCP endpoint needs configuration${NC}"
fi

# Step 9: Summary
echo ""
echo "======================================"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "📍 Backend URL: $SERVICE_URL"
echo "📍 Worker URL: https://rapidtriage.me"
echo "📍 Health Check: https://rapidtriage.me/health"
echo ""
echo "🔧 Next Steps:"
echo "1. Monitor logs: gcloud run logs read --service $SERVICE_NAME"
echo "2. Scale if needed: gcloud run services update $SERVICE_NAME --max-instances 50"
echo "3. Set up monitoring: https://console.cloud.google.com/monitoring"
echo ""
echo "📊 View metrics:"
echo "- Cloud Run: https://console.cloud.google.com/run"
echo "- Cloudflare: https://dash.cloudflare.com"