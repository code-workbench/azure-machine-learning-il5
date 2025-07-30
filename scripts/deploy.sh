#!/bin/bash

# Azure Machine Learning Infrastructure Deployment Script
# This script deploys the Bicep template for Azure ML workspace with private endpoints

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
ENVIRONMENT_NAME="azml-demo"
LOCATION="usgovvirginia"
ADMIN_USERNAME="azureadmin"
VM_SIZE="Standard_D2s_v3"
RESOURCE_GROUP=""
ADMIN_PASSWORD=""

# Help function
show_help() {
    cat << EOF
Azure Machine Learning Infrastructure Deployment Script

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -e, --environment       Environment name (default: azml-demo)
    -l, --location          Azure region (default: eastus)
    -g, --resource-group    Resource group name (required)
    -u, --admin-username    VM admin username (default: azureadmin)
    -p, --admin-password    VM admin password (required)
    -s, --vm-size          VM size (default: Standard_D2s_v3)
    --dry-run              Validate template without deploying
    --what-if              Show what resources would be created/modified

Examples:
    $0 -g rg-ml-dev -p "YourSecurePassword123!"
    $0 -g rg-ml-prod -e prod -l westus2 -p "YourSecurePassword123!"
    $0 -g rg-ml-dev -p "YourSecurePassword123!" --dry-run

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -e|--environment)
            ENVIRONMENT_NAME="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -u|--admin-username)
            ADMIN_USERNAME="$2"
            shift 2
            ;;
        -p|--admin-password)
            ADMIN_PASSWORD="$2"
            shift 2
            ;;
        -s|--vm-size)
            VM_SIZE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --what-if)
            WHAT_IF=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$RESOURCE_GROUP" ]]; then
    print_error "Resource group is required. Use -g or --resource-group to specify."
    show_help
    exit 1
fi

if [[ -z "$ADMIN_PASSWORD" ]]; then
    print_error "Admin password is required. Use -p or --admin-password to specify."
    show_help
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$PROJECT_ROOT/infra"

# Validate files exist
if [[ ! -f "$INFRA_DIR/main.bicep" ]]; then
    print_error "main.bicep not found at $INFRA_DIR/main.bicep"
    exit 1
fi

if [[ ! -f "$INFRA_DIR/abbreviations.json" ]]; then
    print_error "abbreviations.json not found at $INFRA_DIR/abbreviations.json"
    exit 1
fi

print_status "Starting Azure Machine Learning infrastructure deployment..."
print_status "Environment: $ENVIRONMENT_NAME"
print_status "Location: $LOCATION"
print_status "Resource Group: $RESOURCE_GROUP"
print_status "Admin Username: $ADMIN_USERNAME"
print_status "VM Size: $VM_SIZE"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    print_error "Azure CLI is not installed. Please install it first: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in to Azure
print_status "Checking Azure CLI authentication..."
if ! az account show &> /dev/null; then
    print_error "You are not logged in to Azure. Please run 'az login' first."
    exit 1
fi

# Get current subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
print_status "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# Check if resource group exists, create if it doesn't
print_status "Checking if resource group exists..."
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_warning "Resource group '$RESOURCE_GROUP' does not exist. Creating it..."
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
    print_success "Resource group created successfully"
else
    print_status "Resource group '$RESOURCE_GROUP' already exists"
fi

# Build deployment parameters
DEPLOYMENT_PARAMS=(
    "environmentName=$ENVIRONMENT_NAME"
    "location=$LOCATION"
    "adminUsername=$ADMIN_USERNAME"
    "adminPassword=$ADMIN_PASSWORD"
    "vmSize=$VM_SIZE"
)

# Create parameter string
PARAM_STRING=""
for param in "${DEPLOYMENT_PARAMS[@]}"; do
    PARAM_STRING="$PARAM_STRING --parameters $param"
done

# Generate deployment name with timestamp
DEPLOYMENT_NAME="azml-deployment-$(date +%Y%m%d-%H%M%S)"

if [[ "$DRY_RUN" == "true" ]]; then
    print_status "Running template validation (dry run)..."
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$INFRA_DIR/main.bicep" \
        --name "$DEPLOYMENT_NAME" \
        $PARAM_STRING
    
    print_success "Template validation completed successfully!"
    exit 0
fi

if [[ "$WHAT_IF" == "true" ]]; then
    print_status "Running what-if analysis..."
    az deployment group what-if \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$INFRA_DIR/main.bicep" \
        --name "$DEPLOYMENT_NAME" \
        $PARAM_STRING
    
    exit 0
fi

# Deploy the template
print_status "Starting deployment: $DEPLOYMENT_NAME"
print_status "This may take 10-15 minutes..."

DEPLOYMENT_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$INFRA_DIR/main.bicep" \
    --name "$DEPLOYMENT_NAME" \
    $PARAM_STRING \
    --output json)

if [[ $? -eq 0 ]]; then
    print_success "Deployment completed successfully!"
    
    # Extract and display outputs
    print_status "Deployment outputs:"
    echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs | to_entries[] | "  \(.key): \(.value.value)"'
    
    # Extract connection information
    JUMPBOX_FQDN=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.jumpboxFqdn.value')
    ML_WORKSPACE_NAME=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.properties.outputs.mlWorkspaceName.value')
    
    echo ""
    print_success "Infrastructure deployed successfully!"
    echo ""
    print_status "Next steps:"
    echo "  1. Connect to jumpbox via RDP:"
    echo "     Server: $JUMPBOX_FQDN"
    echo "     Username: $ADMIN_USERNAME"
    echo "     Port: 3389"
    echo ""
    echo "  2. Access Azure ML Studio:"
    echo "     https://ml.azure.com"
    echo "     Workspace: $ML_WORKSPACE_NAME"
    echo ""
    echo "  3. The jumpbox provides secure access to your private Azure ML workspace"
    echo "     All ML services are accessible only through private endpoints"
    
else
    print_error "Deployment failed!"
    exit 1
fi
