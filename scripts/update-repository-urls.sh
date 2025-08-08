#!/bin/bash

# Script: update-repository-urls.sh
# Purpose: Update all repository URLs from .project configuration
# This script reads the repository URL from .project and updates all references

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Repository URL Update Script${NC}"
echo -e "${BLUE}========================================${NC}"

# Read configuration from .project
PROJECT_FILE=".project"
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}Error: .project file not found${NC}"
    exit 1
fi

# Parse .project file
while IFS='=' read -r key value; do
    if [[ ! -z "$key" && ! -z "$value" ]]; then
        export "$key=$value"
    fi
done < "$PROJECT_FILE"

echo -e "${GREEN}Configuration loaded from .project:${NC}"
echo -e "  Project: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "  Repository: ${YELLOW}$REPOSITORY_URL${NC}"
echo -e "  Domain: ${YELLOW}$DOMAIN${NC}"
echo ""

# Extract GitHub org and repo from URL
GITHUB_ORG=$(echo $REPOSITORY_URL | cut -d'/' -f4)
GITHUB_REPO=$(echo $REPOSITORY_URL | cut -d'/' -f5)

echo -e "${BLUE}Extracted values:${NC}"
echo -e "  GitHub Org: ${YELLOW}$GITHUB_ORG${NC}"
echo -e "  GitHub Repo: ${YELLOW}$GITHUB_REPO${NC}"
echo ""

# Define old patterns to replace
OLD_PATTERNS=(
    "https://github.com/yarlisai/rapidtriage"
    "github.com/yarlisai/rapidtriage"
    "yarlisai/rapidtriage"
)

# Define new patterns
NEW_URL="$REPOSITORY_URL"
NEW_SHORT="${GITHUB_ORG}/${GITHUB_REPO}"

# Function to update files
update_files() {
    local pattern=$1
    local replacement=$2
    local file_type=$3
    
    echo -e "${YELLOW}Searching for: ${pattern}${NC}"
    
    # Find files containing the pattern
    files=$(grep -rl "$pattern" . \
        --include="*.md" \
        --include="*.yml" \
        --include="*.yaml" \
        --include="*.json" \
        --include="*.ts" \
        --include="*.js" \
        --include="*.html" \
        --exclude-dir=node_modules \
        --exclude-dir=.git \
        --exclude-dir=dist \
        --exclude-dir=build \
        2>/dev/null || true)
    
    if [ -z "$files" ]; then
        echo -e "  ${GREEN}No occurrences found${NC}"
        return
    fi
    
    # Count occurrences
    count=$(echo "$files" | wc -l | tr -d ' ')
    echo -e "  Found in ${BLUE}$count${NC} files"
    
    # Update each file
    for file in $files; do
        echo -e "  Updating: ${BLUE}$file${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|$pattern|$replacement|g" "$file"
        else
            # Linux
            sed -i "s|$pattern|$replacement|g" "$file"
        fi
    done
    
    echo -e "  ${GREEN}✓ Updated $count files${NC}"
    echo ""
}

# Update all patterns
echo -e "${BLUE}Starting URL updates...${NC}"
echo ""

# Update full URLs
update_files "https://github.com/yarlisai/rapidtriage" "$NEW_URL"

# Update short references
update_files "github.com/yarlisai/rapidtriage" "${NEW_URL#https://}"

# Update org/repo references
update_files "yarlisai/rapidtriage" "$NEW_SHORT"

# Update MkDocs configuration specifically
echo -e "${BLUE}Updating MkDocs configuration...${NC}"
for mkdocs_file in mkdocs.yml mkdocs-simple.yml; do
    if [ -f "$mkdocs_file" ]; then
        echo -e "  Updating: ${BLUE}$mkdocs_file${NC}"
        
        # Update repo_url
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|repo_url:.*|repo_url: $REPOSITORY_URL|" "$mkdocs_file"
            sed -i '' "s|repo_name:.*|repo_name: $NEW_SHORT|" "$mkdocs_file"
            sed -i '' "s|site_author:.*|site_author: $GITHUB_ORG|" "$mkdocs_file"
        else
            sed -i "s|repo_url:.*|repo_url: $REPOSITORY_URL|" "$mkdocs_file"
            sed -i "s|repo_name:.*|repo_name: $NEW_SHORT|" "$mkdocs_file"
            sed -i "s|site_author:.*|site_author: $GITHUB_ORG|" "$mkdocs_file"
        fi
        
        echo -e "  ${GREEN}✓ Updated${NC}"
    fi
done
echo ""

# Rebuild documentation if mkdocs is installed
if command -v mkdocs &> /dev/null; then
    echo -e "${BLUE}Rebuilding documentation...${NC}"
    mkdocs build --quiet
    echo -e "${GREEN}✓ Documentation rebuilt${NC}"
    echo ""
fi

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Summary:${NC}"
echo -e "  Old URL: ${RED}https://github.com/yarlisai/rapidtriage${NC}"
echo -e "  New URL: ${GREEN}$REPOSITORY_URL${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review the changes: git diff"
echo "  2. Commit the changes: git add -A && git commit -m 'Update repository URLs'"
echo "  3. Push to repository: git push origin main"
echo "  4. Redeploy documentation: mkdocs gh-deploy --force"
echo ""
echo -e "${GREEN}Configuration is now centralized in .project file${NC}"
echo -e "${GREEN}Future updates: Simply edit .project and run this script${NC}"