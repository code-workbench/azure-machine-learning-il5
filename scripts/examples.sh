#!/bin/bash

# Example deployment script for Azure Machine Learning Infrastructure
# This script shows different ways to deploy the infrastructure

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Azure ML Infrastructure Deployment Examples${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}1. Basic deployment (development environment):${NC}"
echo "   $SCRIPT_DIR/deploy.sh -g rg-ml-dev -p \"YourSecurePassword123!\""
echo ""

echo -e "${GREEN}2. Production deployment with custom settings:${NC}"
echo "   $SCRIPT_DIR/deploy.sh \\"
echo "     --resource-group rg-ml-prod \\"
echo "     --environment prod \\"
echo "     --location westus2 \\"
echo "     --admin-username prodadmin \\"
echo "     --admin-password \"YourSecurePassword123!\" \\"
echo "     --vm-size Standard_D4s_v3"
echo ""

echo -e "${GREEN}3. Validate template without deploying (dry run):${NC}"
echo "   $SCRIPT_DIR/deploy.sh -g rg-ml-dev -p \"YourSecurePassword123!\" --dry-run"
echo ""

echo -e "${GREEN}4. See what resources would be created/modified:${NC}"
echo "   $SCRIPT_DIR/deploy.sh -g rg-ml-dev -p \"YourSecurePassword123!\" --what-if"
echo ""

echo -e "${GREEN}5. Help and all available options:${NC}"
echo "   $SCRIPT_DIR/deploy.sh --help"
echo ""

echo "Note: Make sure you're logged in to Azure CLI first:"
echo "   az login"
echo ""
echo "You can also set your default subscription:"
echo "   az account set --subscription \"your-subscription-name-or-id\""
