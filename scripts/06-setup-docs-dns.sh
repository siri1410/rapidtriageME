#!/bin/bash

# Script: 06-setup-docs-dns.sh
# Purpose: Configure DNS for docs.rapidtriage.me to point to GitHub Pages

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up DNS for docs.rapidtriage.me${NC}"

# Load environment variables
source ./scripts/01-load-env.sh

# Check if required variables are set
if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    echo -e "${RED}Error: CLOUDFLARE_ZONE_ID not set${NC}"
    echo "Please set CLOUDFLARE_ZONE_ID in your .env file"
    exit 1
fi

# Function to check if DNS record exists
check_dns_record() {
    local name=$1
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?name=${name}.rapidtriage.me" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" | jq -r '.result | length'
}

# Function to create DNS record
create_dns_record() {
    local type=$1
    local name=$2
    local content=$3
    local proxied=${4:-false}
    
    echo -e "${YELLOW}Creating ${type} record for ${name}.rapidtriage.me -> ${content}${NC}"
    
    response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{
            \"type\": \"${type}\",
            \"name\": \"${name}\",
            \"content\": \"${content}\",
            \"ttl\": 1,
            \"proxied\": ${proxied}
        }")
    
    success=$(echo $response | jq -r '.success')
    if [ "$success" = "true" ]; then
        echo -e "${GREEN}✅ ${type} record created successfully${NC}"
    else
        echo -e "${RED}❌ Failed to create ${type} record${NC}"
        echo $response | jq .
    fi
}

# Check if we need to use OAuth instead of API token
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    echo -e "${YELLOW}No API token found, using wrangler for DNS setup${NC}"
    
    # Create a temporary JSON file for the DNS record
    cat > /tmp/docs-dns.json << EOF
{
    "type": "CNAME",
    "name": "docs",
    "content": "yarlisaisolutions.github.io",
    "ttl": 1,
    "proxied": false
}
EOF
    
    echo -e "${YELLOW}Please add the following DNS record manually in Cloudflare Dashboard:${NC}"
    echo -e "${GREEN}Type: CNAME${NC}"
    echo -e "${GREEN}Name: docs${NC}"
    echo -e "${GREEN}Content: yarlisaisolutions.github.io${NC}"
    echo -e "${GREEN}Proxy status: DNS only (disabled)${NC}"
    echo ""
    echo -e "${YELLOW}Or use the Cloudflare Dashboard:${NC}"
    echo "1. Go to https://dash.cloudflare.com"
    echo "2. Select your domain (rapidtriage.me)"
    echo "3. Go to DNS settings"
    echo "4. Add the CNAME record as shown above"
    
else
    # Check if docs CNAME already exists
    existing=$(check_dns_record "docs")
    
    if [ "$existing" -gt "0" ]; then
        echo -e "${YELLOW}DNS record for docs.rapidtriage.me already exists${NC}"
        echo "Checking current configuration..."
        
        # Get existing record details
        curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CLOUDFLARE_ZONE_ID}/dns_records?name=docs.rapidtriage.me" \
            -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
            -H "Content-Type: application/json" | jq '.result[0] | {type, name, content, proxied}'
    else
        # Create CNAME record for docs.rapidtriage.me
        create_dns_record "CNAME" "docs" "yarlisaisolutions.github.io" "false"
    fi
fi

echo ""
echo -e "${GREEN}GitHub Pages Configuration${NC}"
echo "------------------------"
echo "1. Create a file named 'CNAME' in the docs-site directory:"
echo "   echo 'docs.rapidtriage.me' > docs-site/CNAME"
echo ""
echo "2. Commit and push the CNAME file:"
echo "   git add docs-site/CNAME"
echo "   git commit -m 'Add CNAME for custom domain'"
echo "   git push origin main"
echo ""
echo "3. Rebuild and deploy docs:"
echo "   mkdocs gh-deploy --force"
echo ""

# Create CNAME file for GitHub Pages
echo -e "${YELLOW}Creating CNAME file for GitHub Pages...${NC}"
echo "docs.rapidtriage.me" > docs-site/CNAME
echo -e "${GREEN}✅ CNAME file created${NC}"

echo ""
echo -e "${GREEN}DNS Setup Complete!${NC}"
echo "------------------------"
echo "Documentation will be available at:"
echo "  https://docs.rapidtriage.me (after DNS propagation)"
echo "  https://yarlisaisolutions.github.io/rapidtriageME/ (immediate)"
echo ""
echo "DNS propagation may take 5-30 minutes."
echo ""
echo "To verify DNS:"
echo "  dig CNAME docs.rapidtriage.me"
echo "  nslookup docs.rapidtriage.me"