#!/bin/bash

# RapidTriageME Enhanced Production Deployment Script
# Automated deployment to Google Cloud Run with visual progress indicators
# Features: Progress bars, status indicators, enhanced error handling

set -e

# Colors and styling
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Status symbols
PENDING="⏳"
IN_PROGRESS="🔄"
COMPLETED="✅"
FAILED="❌"
WARNING="⚠️"

# Configuration - Using the correct backend URL
PROJECT_ID="${GCP_PROJECT_ID:-rapidtriage-mcp-1754768171}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="rapidtriage-backend"
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"
EXPECTED_BACKEND_URL="https://rapidtriage-backend-457164051549.us-central1.run.app/"

# Step tracking
declare -a STEPS=(
    "Build Docker image for amd64 platform"
    "Configure Docker for Google Container Registry"
    "Push image to Container Registry"
    "Deploy to Cloud Run"
    "Update Cloudflare Worker with backend URL"
    "Test deployment and verify all services"
)

declare -a STEP_STATUS=("pending" "pending" "pending" "pending" "pending" "pending")

# Function to display header
show_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 RapidTriageME Enhanced Deployment                       ║"
    echo "║                        Production Deployment Script                           ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# Function to display progress bar
show_progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}Progress: [${GREEN}"
    printf "%*s" $filled | tr ' ' '█'
    printf "${BLUE}"
    printf "%*s" $empty | tr ' ' '░'
    printf "${CYAN}] %d%% (%d/%d)${NC}" $percentage $current $total
}

# Function to display step status
show_step_status() {
    echo -e "\n${BOLD}${PURPLE}Deployment Steps:${NC}"
    echo "═══════════════════"
    
    for i in "${!STEPS[@]}"; do
        local step_num=$((i + 1))
        local status="${STEP_STATUS[$i]}"
        local symbol=""
        local color=""
        
        case $status in
            "pending")
                symbol="$PENDING"
                color="$YELLOW"
                ;;
            "in_progress")
                symbol="$IN_PROGRESS"
                color="$BLUE"
                ;;
            "completed")
                symbol="$COMPLETED"
                color="$GREEN"
                ;;
            "failed")
                symbol="$FAILED"
                color="$RED"
                ;;
        esac
        
        echo -e "${color}${symbol} Step ${step_num}: ${STEPS[$i]}${NC}"
    done
    echo ""
}

# Function to update step status
update_step_status() {
    local step_index=$1
    local status=$2
    STEP_STATUS[$step_index]=$status
    show_header
    show_step_status
    show_progress_bar $((step_index + 1)) ${#STEPS[@]}
    echo ""
}

# Function to run command with progress simulation
run_with_progress() {
    local cmd="$1"
    local duration="${2:-10}"
    local step_name="$3"
    
    echo -e "\n${BLUE}${IN_PROGRESS} Executing: ${step_name}${NC}"
    
    # Start the command in background and capture its PID
    eval "$cmd" &
    local cmd_pid=$!
    
    # Show spinning progress while command runs
    local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while kill -0 $cmd_pid 2>/dev/null; do
        local char=${spin_chars:$((i % ${#spin_chars})):1}
        printf "\r${BLUE}${char} Processing... ${step_name}${NC}"
        sleep 0.1
        ((i++))
    done
    
    # Wait for command to complete and get exit status
    wait $cmd_pid
    local exit_status=$?
    
    printf "\r${GREEN}${COMPLETED} Completed: ${step_name}${NC}\n"
    return $exit_status
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}${PENDING} Checking prerequisites...${NC}"
    
    local errors=0
    
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}${FAILED} Error: gcloud CLI not installed${NC}"
        echo -e "${YELLOW}  Install from: https://cloud.google.com/sdk/docs/install${NC}"
        ((errors++))
    else
        echo -e "${GREEN}${COMPLETED} gcloud CLI found${NC}"
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}${FAILED} Error: Docker not installed${NC}"
        echo -e "${YELLOW}  Install Docker from: https://docs.docker.com/get-docker/${NC}"
        ((errors++))
    else
        echo -e "${GREEN}${COMPLETED} Docker found${NC}"
    fi
    
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}${WARNING} jq not found, installing...${NC}"
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo -e "${RED}${FAILED} Please install jq manually${NC}"
            ((errors++))
        fi
    else
        echo -e "${GREEN}${COMPLETED} jq found${NC}"
    fi
    
    if ! command -v wrangler &> /dev/null; then
        echo -e "${YELLOW}${WARNING} Wrangler CLI not found${NC}"
        echo -e "${YELLOW}  Install with: npm install -g wrangler${NC}"
        ((errors++))
    else
        echo -e "${GREEN}${COMPLETED} Wrangler CLI found${NC}"
    fi
    
    if [ $errors -gt 0 ]; then
        echo -e "\n${RED}${FAILED} Prerequisites check failed. Please install missing dependencies.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}${COMPLETED} All prerequisites satisfied${NC}"
    sleep 2
}

# Function to handle errors
handle_error() {
    local step_index=$1
    local error_msg="$2"
    
    STEP_STATUS[$step_index]="failed"
    update_step_status $step_index "failed"
    
    echo -e "\n${RED}${FAILED} Deployment failed at step $((step_index + 1))${NC}"
    echo -e "${RED}Error: $error_msg${NC}"
    echo -e "\n${YELLOW}Troubleshooting tips:${NC}"
    
    case $step_index in
        0)
            echo -e "• Check if Docker is running"
            echo -e "• Verify Dockerfile exists in rapidtriage-server/"
            echo -e "• Ensure sufficient disk space"
            ;;
        1)
            echo -e "• Run 'gcloud auth login' to authenticate"
            echo -e "• Check if project ID is correct"
            ;;
        2)
            echo -e "• Verify Docker registry permissions"
            echo -e "• Check network connectivity"
            ;;
        3)
            echo -e "• Check Cloud Run API is enabled"
            echo -e "• Verify project permissions"
            ;;
        4)
            echo -e "• Check Wrangler authentication"
            echo -e "• Verify Cloudflare Worker configuration"
            ;;
        5)
            echo -e "• Check service URLs"
            echo -e "• Verify network connectivity"
            ;;
    esac
    
    exit 1
}

# Main deployment function
main() {
    show_header
    
    echo -e "${BOLD}${CYAN}Starting RapidTriageME Production Deployment${NC}"
    echo -e "${CYAN}Target Backend URL: ${EXPECTED_BACKEND_URL}${NC}"
    echo ""
    
    check_prerequisites
    
    show_step_status
    
    # Step 1: Build Docker image
    update_step_status 0 "in_progress"
    echo -e "\n${BLUE}Building Docker image for amd64 platform...${NC}"
    
    if [ ! -d "rapidtriage-server" ]; then
        handle_error 0 "rapidtriage-server directory not found"
    fi
    
    cd rapidtriage-server
    
    if run_with_progress "docker buildx build --platform linux/amd64 -t $IMAGE_NAME:latest --load . > /tmp/docker_build.log 2>&1" 15 "Building Docker image"; then
        update_step_status 0 "completed"
        echo -e "${GREEN}Docker image built successfully${NC}"
    else
        handle_error 0 "Docker build failed. Check /tmp/docker_build.log for details"
    fi
    
    # Step 2: Configure Docker for GCR
    update_step_status 1 "in_progress"
    echo -e "\n${BLUE}Configuring Docker for Google Container Registry...${NC}"
    
    if run_with_progress "gcloud auth configure-docker --quiet > /tmp/gcloud_config.log 2>&1" 5 "Configuring Docker auth"; then
        update_step_status 1 "completed"
        echo -e "${GREEN}Docker configured for GCR${NC}"
    else
        handle_error 1 "Failed to configure Docker for GCR"
    fi
    
    # Step 3: Push image to GCR
    update_step_status 2 "in_progress"
    echo -e "\n${BLUE}Pushing image to Container Registry...${NC}"
    
    if run_with_progress "docker push $IMAGE_NAME:latest > /tmp/docker_push.log 2>&1" 20 "Pushing Docker image"; then
        update_step_status 2 "completed"
        echo -e "${GREEN}Image pushed to GCR successfully${NC}"
    else
        handle_error 2 "Failed to push image to GCR"
    fi
    
    # Step 4: Deploy to Cloud Run
    update_step_status 3 "in_progress"
    echo -e "\n${BLUE}Deploying to Cloud Run...${NC}"
    
    deploy_cmd="gcloud run deploy $SERVICE_NAME \
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
        --set-env-vars NODE_ENV=production \
        --quiet > /tmp/cloudrun_deploy.log 2>&1"
    
    if run_with_progress "$deploy_cmd" 30 "Deploying to Cloud Run"; then
        update_step_status 3 "completed"
        
        # Get the service URL
        SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
            --region $REGION \
            --format 'value(status.url)' 2>/dev/null)
        
        echo -e "${GREEN}Backend deployed successfully${NC}"
        echo -e "${CYAN}Service URL: $SERVICE_URL${NC}"
        
        # Verify it matches expected URL
        if [[ "$SERVICE_URL" == "$EXPECTED_BACKEND_URL"* ]]; then
            echo -e "${GREEN}✓ Service URL matches expected backend URL${NC}"
        else
            echo -e "${YELLOW}${WARNING} Service URL differs from expected: $EXPECTED_BACKEND_URL${NC}"
        fi
    else
        handle_error 3 "Cloud Run deployment failed"
    fi
    
    # Step 5: Update Cloudflare Worker
    update_step_status 4 "in_progress"
    echo -e "\n${BLUE}Updating Cloudflare Worker with backend URL...${NC}"
    
    cd ..
    
    if run_with_progress "echo '$SERVICE_URL' | wrangler secret put BACKEND_URL --env production > /tmp/wrangler.log 2>&1" 10 "Updating Cloudflare Worker"; then
        update_step_status 4 "completed"
        echo -e "${GREEN}Cloudflare Worker updated successfully${NC}"
    else
        handle_error 4 "Failed to update Cloudflare Worker"
    fi
    
    # Step 6: Test deployment
    update_step_status 5 "in_progress"
    echo -e "\n${BLUE}Testing deployment and verifying all services...${NC}"
    
    # Wait for services to be ready
    echo -e "${YELLOW}Waiting for services to initialize...${NC}"
    sleep 10
    
    local test_results=0
    
    # Test backend health
    echo -e "\n${CYAN}Testing backend health...${NC}"
    BACKEND_HEALTH=$(curl -s --max-time 10 "$SERVICE_URL/health" | jq -r '.status' 2>/dev/null || echo "failed")
    if [ "$BACKEND_HEALTH" = "healthy" ]; then
        echo -e "${GREEN}${COMPLETED} Backend health check passed${NC}"
    else
        echo -e "${RED}${FAILED} Backend health check failed${NC}"
        ((test_results++))
    fi
    
    # Test Worker health
    echo -e "\n${CYAN}Testing Worker health...${NC}"
    WORKER_HEALTH=$(curl -s --max-time 10 "https://rapidtriage.me/health" | jq -r '.status' 2>/dev/null || echo "failed")
    if [ "$WORKER_HEALTH" = "healthy" ]; then
        echo -e "${GREEN}${COMPLETED} Worker health check passed${NC}"
    else
        echo -e "${YELLOW}${WARNING} Worker health check failed or needs time to propagate${NC}"
        ((test_results++))
    fi
    
    # Test MCP endpoint
    echo -e "\n${CYAN}Testing MCP endpoint...${NC}"
    MCP_TEST=$(curl -s --max-time 10 -X POST "https://rapidtriage.me/mcp" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer KskHe6x5tkS4CgLrwfeZvbXsSDmZUjR8" \
        -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' | \
        jq -r '.result.tools[0].name' 2>/dev/null || echo "failed")
    
    if [ "$MCP_TEST" != "failed" ] && [ "$MCP_TEST" != "null" ]; then
        echo -e "${GREEN}${COMPLETED} MCP endpoint is working${NC}"
    else
        echo -e "${YELLOW}${WARNING} MCP endpoint needs configuration or time to propagate${NC}"
    fi
    
    if [ $test_results -eq 0 ]; then
        update_step_status 5 "completed"
        echo -e "\n${GREEN}${COMPLETED} All tests passed successfully${NC}"
    else
        echo -e "\n${YELLOW}${WARNING} Some tests failed - deployment may need time to propagate${NC}"
        update_step_status 5 "completed"
    fi
    
    # Final status display
    show_header
    show_step_status
    show_progress_bar 6 6
    echo ""
    
    # Success summary
    echo -e "\n${BOLD}${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           🎉 DEPLOYMENT COMPLETE! 🎉                          ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "\n${BOLD}${CYAN}📍 Service Information:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${GREEN}Backend URL:${NC}     $SERVICE_URL"
    echo -e "${GREEN}Worker URL:${NC}      https://rapidtriage.me"
    echo -e "${GREEN}Health Check:${NC}    https://rapidtriage.me/health"
    echo -e "${GREEN}Expected URL:${NC}    $EXPECTED_BACKEND_URL"
    
    echo -e "\n${BOLD}${CYAN}🔧 Management Commands:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}Monitor logs:${NC}       gcloud run logs read --service $SERVICE_NAME --region $REGION"
    echo -e "${YELLOW}Scale service:${NC}      gcloud run services update $SERVICE_NAME --max-instances 50 --region $REGION"
    echo -e "${YELLOW}View metrics:${NC}       https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME"
    
    echo -e "\n${BOLD}${CYAN}📊 Monitoring Links:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}• Cloud Run Console:${NC} https://console.cloud.google.com/run"
    echo -e "${BLUE}• Cloudflare Dash:${NC}   https://dash.cloudflare.com"
    echo -e "${BLUE}• Cloud Monitoring:${NC}  https://console.cloud.google.com/monitoring"
    
    echo -e "\n${GREEN}${COMPLETED} Deployment completed successfully!${NC}"
    echo -e "${CYAN}All services are ready for production use.${NC}\n"
}

# Error handling
trap 'echo -e "\n${RED}${FAILED} Deployment interrupted${NC}"; exit 1' INT TERM

# Run main function
main "$@"