RapidTriageME Testing and Deployment Playbook

  📋 Complete Testing and Deployment Guide

  This playbook documents all commands and steps executed to test the
  RapidTriageME platform and deploy it to production.

  ---
  🚀 Prerequisites

  Environment Setup

  # Verify Node.js installation
  node --version  # Should be v18.0.0 or higher

  # Verify npm installation
  npm --version   # Should be v9.0.0 or higher

  # Verify Python installation (for test server)
  python3 --version

  ---
  📂 Project Structure Setup

  1. Navigate to Project Directory

  cd /Users/yarlis/Downloads/rapidtriageME

  2. Check Git Status

  git status

  ---
  🖥️ Local Server Setup

  1. Start RapidTriage Server

  # Navigate to server directory
  cd rapidtriage-server

  # Start the server (runs on port 3025)
  node server.js

  2. Start Test Page HTTP Server

  # In project root directory
  python3 -m http.server 8080

  3. Open Test Page in Browser

  open http://localhost:8080/test-rapidtriage-enhanced.html

  ---
  🧪 MCP Function Testing

  1. Take Screenshot

  # Using MCP tool (programmatically)
  mcp__rapidtriage-local__takeScreenshot

  2. Get Console Logs

  # Using MCP tool
  mcp__rapidtriage-local__getConsoleLogs

  3. Get Console Errors

  # Using MCP tool
  mcp__rapidtriage-local__getConsoleErrors

  4. Get Network Logs

  # Using MCP tool
  mcp__rapidtriage-local__getNetworkLogs

  5. Get Network Errors

  # Using MCP tool
  mcp__rapidtriage-local__getNetworkErrors

  6. Wipe All Logs

  # Using MCP tool
  mcp__rapidtriage-local__wipeLogs

  7. Get Selected Element

  # Using MCP tool
  mcp__rapidtriage-local__getSelectedElement

  8. Run Accessibility Audit

  # Using MCP tool
  mcp__rapidtriage-local__runAccessibilityAudit

  9. Run Performance Audit

  # Using MCP tool
  mcp__rapidtriage-local__runPerformanceAudit

  10. Run SEO Audit

  # Using MCP tool
  mcp__rapidtriage-local__runSEOAudit

  11. Run Best Practices Audit

  # Using MCP tool
  mcp__rapidtriage-local__runBestPracticesAudit

  ---
  🚢 Production Deployment

  Deploy to Production

  # Run the deployment script
  ./deploy-production.sh

  This script automatically:
  1. Builds Docker image for amd64 platform
  2. Configures Docker for Google Container Registry
  3. Pushes image to GCR
  4. Deploys to Google Cloud Run
  5. Updates Cloudflare Worker with backend URL
  6. Tests the deployment

  ---
  🔍 Verification Commands

  Check Server Status

  # Check if server is running on port 3025
  lsof -i :3025

  # Check server health
  curl http://localhost:3025/health

  Test Production Endpoints

  # Test backend health
  curl https://rapidtriage-backend-u72y6ntcwa-uc.a.run.app/health

  # Test Worker health
  curl https://rapidtriage.me/health

  # Test MCP endpoint (requires authentication)
  curl -X POST https://rapidtriage.me/mcp \
    -H "Authorization: Bearer YOUR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}'

  ---
  📊 Test Results Summary

  | Feature              | Status    | Score/Result               |
  |----------------------|-----------|----------------------------|
  | Screenshot Capture   | ✅ Working | N/A                        |
  | Console Logs         | ✅ Working | Empty when no logs         |
  | Console Errors       | ✅ Working | 2 XSS test errors captured |
  | Network Logs         | ✅ Working | 3 requests captured        |
  | Network Errors       | ✅ Working | None detected              |
  | Wipe Logs            | ✅ Working | Successfully cleared       |
  | Selected Element     | ✅ Working | "No element selected"      |
  | Accessibility Audit  | ✅ Working | 80/100                     |
  | Performance Audit    | ✅ Working | 97/100                     |
  | SEO Audit            | ✅ Working | 80/100                     |
  | Best Practices Audit | ✅ Working | 96/100                     |

  ---
  🔧 Troubleshooting Commands

  If Server Port is Already in Use

  # Find process using port 3025
  lsof -i :3025

  # Kill the process (replace PID with actual process ID)
  kill -9 PID

  Check Docker Status

  # List Docker images
  docker images

  # Check running containers
  docker ps

  # View Docker logs
  docker logs CONTAINER_ID

  Monitor Cloud Run Logs

  # View Cloud Run service logs
  gcloud run logs read --service rapidtriage-backend

  # Stream logs in real-time
  gcloud run logs tail --service rapidtriage-backend

  Check Cloudflare Worker Logs

  # Tail Cloudflare Worker logs
  wrangler tail rapidtriage-me-production

  ---
  📍 Production URLs

  - Backend API: https://rapidtriage-backend-u72y6ntcwa-uc.a.run.app
  - Cloudflare Worker: https://rapidtriage.me
  - Health Check: https://rapidtriage.me/health
  - MCP Endpoint: https://rapidtriage.me/mcp

  ---
  🎯 Next Steps

  1. Monitor Production
  # Set up monitoring
  gcloud run services update rapidtriage-backend --max-instances 50
  2. Scale if Needed
  # Update max instances
  gcloud run services update rapidtriage-backend --max-instances 100
  3. View Metrics
    - Cloud Run: https://console.cloud.google.com/run
    - Cloudflare: https://dash.cloudflare.com

  ---
  📝 Notes

  - The console errors detected during testing are intentional (XSS
  protection tests)
  - All MCP functions are working correctly
  - The deployment automatically handles Docker image building, GCR
  push, and Cloud Run deployment
  - Cloudflare Worker is automatically updated with the new backend URL

  ---
  🔐 Security Considerations

  - Always use HTTPS in production
  - Keep API tokens secure
  - Monitor for unusual activity in logs
  - Regularly update dependencies

  ---
  Last tested: August 9, 2025
  Platform: macOS Darwin 24.5.0
  Node.js: v20.19.1