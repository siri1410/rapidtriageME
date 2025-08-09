#!/bin/bash

# RapidTriageME MCP Configuration Verification Script

echo "🔍 Verifying RapidTriageME MCP Setup for Claude Code"
echo "===================================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if settings.json exists and has MCP configuration
echo -e "\n${YELLOW}1. Checking Claude Code settings...${NC}"
if [ -f ~/.claude/settings.json ]; then
    if grep -q "rapidtriage" ~/.claude/settings.json; then
        echo -e "${GREEN}✅ RapidTriageME MCP server found in settings.json${NC}"
        echo "   Configured servers:"
        grep -A2 "rapidtriage" ~/.claude/settings.json | grep "description" | sed 's/.*"description": "/   - /' | sed 's/".*//'
    else
        echo -e "${RED}❌ RapidTriageME not found in settings.json${NC}"
    fi
else
    echo -e "${RED}❌ Claude Code settings.json not found${NC}"
fi

# Test production endpoint
echo -e "\n${YELLOW}2. Testing production endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s https://rapidtriage.me/health)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Production endpoint is accessible${NC}"
    echo "   Status: $(echo $HEALTH_RESPONSE | jq -r '.status' 2>/dev/null || echo 'Unknown')"
else
    echo -e "${RED}❌ Cannot reach production endpoint${NC}"
fi

# Test MCP protocol
echo -e "\n${YELLOW}3. Testing MCP protocol...${NC}"
MCP_RESPONSE=$(curl -s -X POST https://rapidtriage.me/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer KskHe6x5tkS4CgLrwfeZvbXsSDmZUjR8" \
  -d '{"jsonrpc":"2.0","method":"tools/list","params":{},"id":1}' 2>/dev/null)

if echo "$MCP_RESPONSE" | grep -q "tools"; then
    echo -e "${GREEN}✅ MCP protocol is working${NC}"
    TOOL_COUNT=$(echo "$MCP_RESPONSE" | jq '.result.tools | length' 2>/dev/null || echo "0")
    echo "   Available tools: $TOOL_COUNT"
else
    echo -e "${RED}❌ MCP protocol test failed${NC}"
    echo "   Response: $(echo "$MCP_RESPONSE" | head -c 100)"
fi

# Check local setup
echo -e "\n${YELLOW}4. Checking local setup...${NC}"
if [ -d "/Users/yarlis/Downloads/rapidtriageME/rapidtriage-mcp" ]; then
    echo -e "${GREEN}✅ Local MCP server directory found${NC}"
    if [ -f "/Users/yarlis/Downloads/rapidtriageME/rapidtriage-mcp/dist/mcp-server.js" ]; then
        echo -e "${GREEN}✅ Local MCP server executable found${NC}"
    else
        echo -e "${YELLOW}⚠️  Local MCP server not built. Run: cd rapidtriage-mcp && npm run build${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Local MCP server not found${NC}"
fi

# Summary
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}CONFIGURATION SUMMARY${NC}"
echo -e "${YELLOW}========================================${NC}"

echo -e "\n${GREEN}Production MCP Server:${NC}"
echo "  URL: https://rapidtriage.me/mcp"
echo "  Auth: Bearer KskHe6x5tkS4CgLrwfeZvbXsSDmZUjR8"
echo "  Transport: HTTP"

echo -e "\n${GREEN}Local MCP Server:${NC}"
echo "  Command: node /Users/yarlis/Downloads/rapidtriageME/rapidtriage-mcp/dist/mcp-server.js stdio"
echo "  Transport: stdio"

echo -e "\n${GREEN}Usage with Claude Code:${NC}"
echo '  claude-code chat "Using rapidtriage, take a screenshot of example.com"'
echo '  claude-code chat "With rapidtriage-local, get console logs from github.com"'

echo -e "\n${GREEN}✅ MCP server configuration complete!${NC}"