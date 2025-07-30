#!/bin/bash

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}


# =============================================================================
# Azure Machine Learning Infrastructure Cleanup Script
# ================confirm_deletion() {
    if [ "$FORCE_DELETE" = true ]; then
        log_warning "Force mode enabled - skipping confirmation"
        return
    fi
    
    echo -e "${RED}⚠️  WARNING: This action cannot be undone! ⚠️${NC}"
    echo ""
    echo -e "You are about to delete resource group: ${RED}$RESOURCE_GROUP${NC}"
    echo -e "This will permanently delete ALL resources in this group."
    echo ""
    
    # Double confirmation for safety
    if [ "$FORCE_DELETE" = false ]; then
        read -p "Type the resource group name to confirm deletion: " confirmation
        if [ "$confirmation" != "$RESOURCE_GROUP" ]; then
            log_error "Resource group name doesn't match. Aborting."
            exit 1
        fi
    fi 
    
    read -p "Are you absolutely sure you want to proceed? (yes/no): " final_confirmation
    if [ "$final_confirmation" != "yes" ]; then
        log_info "Deletion cancelled by user."
        exit 0
    fi
}=========================================
# This script safely deletes the Azure resource group and all resources
# created by the Azure ML deployment.
#
# Usage:
#   ./scripts/cleanup.sh --resource-group <rg-name>
#   ./scripts/cleanup.sh -g <rg-name> [--force]
#
# Options:
#   -g, --resource-group    Required. Name of the resource group to delete
#   -f, --force            Skip confirmation prompts
#   -h, --help             Show this help message
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP=""
FORCE_DELETE=false

# =============================================================================
# Helper Functions
# =============================================================================

show_help() {
    cat << EOF
Azure Machine Learning Infrastructure Cleanup Script

USAGE:
    ./scripts/cleanup.sh --resource-group <rg-name> [OPTIONS]

REQUIRED PARAMETERS:
    -g, --resource-group    Name of the resource group to delete

OPTIONS:
    -f, --force            Skip confirmation prompts
    -h, --help             Show this help message

EXAMPLES:
    # Interactive cleanup with confirmation
    ./scripts/cleanup.sh --resource-group rg-ml-dev

    # Force cleanup without prompts (use with caution)
    ./scripts/cleanup.sh -g rg-ml-prod --force

SAFETY FEATURES:
    - Validates Azure CLI authentication
    - Shows resource list before deletion
    - Requires explicit confirmation (unless --force)
    - Provides progress feedback during deletion

EOF
}

validate_prerequisites() {
    if [ "$FORCE_DELETE" = true ]; then
        log_warning "Force mode enabled - skipping prerequisite validation"
        return
    fi
    
    log_info "Validating prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install it first:"
        log_error "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        log_error "You are not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    log_success "Prerequisites validated"
}

check_resource_group_exists() {
    if [ "$FORCE_DELETE" = true ]; then
        log_warning "Force mode enabled - skipping resource group existence check"
        return
    fi
    
    log_info "Checking if resource group '$RESOURCE_GROUP' exists..."
    
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        log_warning "Resource group '$RESOURCE_GROUP' does not exist or you don't have access to it."
        exit 0
    fi
    
    log_success "Resource group '$RESOURCE_GROUP' found"
}

show_resource_summary() {
    if [ "$FORCE_DELETE" = true ]; then
        log_warning "Force mode enabled - skipping resource summary"
        return
    fi
    
    log_info "Analyzing resources in '$RESOURCE_GROUP'..."
    
    # Get resource count
    local resource_count
    resource_count=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length(@)" --output tsv)
    
    if [ "$resource_count" -eq 0 ]; then
        log_warning "Resource group '$RESOURCE_GROUP' is empty."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}=== RESOURCE SUMMARY ===${NC}"
    echo -e "Resource Group: ${BLUE}$RESOURCE_GROUP${NC}"
    echo -e "Total Resources: ${BLUE}$resource_count${NC}"
    echo ""
    
    # Show resource types summary
    echo -e "${YELLOW}Resource Types:${NC}"
    az resource list --resource-group "$RESOURCE_GROUP" \
        --query "[].type" \
        --output tsv | sort | uniq -c | while read count type; do
        echo -e "  ${BLUE}$count${NC} x $type"
    done
    
    echo ""
    echo -e "${YELLOW}Resources to be deleted:${NC}"
    az resource list --resource-group "$RESOURCE_GROUP" \
        --query "[].{Name:name, Type:type, Location:location}" \
        --output table
    
    echo ""
}

confirm_deletion() {
    if [ "$FORCE_DELETE" = true ]; then
        log_warning "Force mode enabled - skipping confirmation"
        return
    fi
    
    echo -e "${RED}⚠️  WARNING: This action cannot be undone! ⚠️${NC}"
    echo ""
    echo -e "You are about to delete resource group: ${RED}$RESOURCE_GROUP${NC}"
    echo -e "This will permanently delete ALL resources in this group."
    echo ""
    
    # Double confirmation for safety
    read -p "Type the resource group name to confirm deletion: " confirmation
    if [ "$confirmation" != "$RESOURCE_GROUP" ]; then
        log_error "Resource group name doesn't match. Aborting."
        exit 1
    fi
    
    read -p "Are you absolutely sure you want to proceed? (yes/no): " final_confirmation
    if [ "$final_confirmation" != "yes" ]; then
        log_info "Deletion cancelled by user."
        exit 0
    fi
}

delete_resource_group() {
    log_info "Starting deletion of resource group '$RESOURCE_GROUP'..."
    log_warning "This operation may take several minutes to complete."
    
    # Start the deletion
    if az group delete --name "$RESOURCE_GROUP" --yes --no-wait; then
        log_success "Deletion initiated successfully!"
        log_info "The resource group is being deleted in the background."
        
        if [ "$FORCE_DELETE" = false ]; then
            echo ""
            log_info "You can monitor the deletion progress with:"
            echo -e "  ${BLUE}az group show --name '$RESOURCE_GROUP'${NC}"
            echo ""
            log_info "The command will fail with 'ResourceGroupNotFound' when deletion is complete."
        fi
    else
        log_error "Failed to initiate resource group deletion."
        exit 1
    fi
}

purge_soft_deleted_workspaces() {
    log_info "Checking for soft-deleted Azure ML workspaces..."
    
    # Get all soft-deleted workspaces in the subscription
    local soft_deleted_workspaces
    soft_deleted_workspaces=$(az ml workspace list-deleted --query "[?resourceGroup=='$RESOURCE_GROUP'].{name:name, location:location}" --output tsv 2>/dev/null || echo "")
    
    if [ -z "$soft_deleted_workspaces" ]; then
        log_info "No soft-deleted Azure ML workspaces found for resource group '$RESOURCE_GROUP'"
        return
    fi
    
    echo ""
    log_warning "Found soft-deleted Azure ML workspaces that need to be purged:"
    echo "$soft_deleted_workspaces" | while IFS=$'\t' read -r workspace_name location; do
        echo -e "  ${BLUE}$workspace_name${NC} (Location: $location)"
    done
    echo ""
    
    if [ "$FORCE_DELETE" = false ]; then
        read -p "Do you want to purge these soft-deleted workspaces? (y/n): " purge_choice
        if [ "$purge_choice" != "y" ] && [ "$purge_choice" != "Y" ]; then
            log_info "Skipping workspace purge. Note: Workspace names will remain reserved."
            return
        fi
    fi
    
    # Purge each soft-deleted workspace
    echo "$soft_deleted_workspaces" | while IFS=$'\t' read -r workspace_name location; do
        if [ -n "$workspace_name" ] && [ -n "$location" ]; then
            log_info "Purging soft-deleted workspace '$workspace_name' in location '$location'..."
            
            if az ml workspace delete --name "$workspace_name" --location "$location" --delete-dependent-resources --all-resources --yes --no-wait 2>/dev/null; then
                log_success "Purge initiated for workspace '$workspace_name'"
            else
                log_warning "Failed to purge workspace '$workspace_name' or it may already be purged"
            fi
        fi
    done
    
    log_success "Soft-deleted workspace purge operations completed"
}

wait_for_deletion() {
    if [ "$FORCE_DELETE" = true ]; then
        return
    fi
    
    read -p "Would you like to wait and monitor the deletion progress? (y/n): " wait_choice
    if [ "$wait_choice" = "y" ] || [ "$wait_choice" = "Y" ]; then
        log_info "Monitoring deletion progress..."
        
        while az group show --name "$RESOURCE_GROUP" &> /dev/null; do
            echo -n "."
            sleep 10
        done
        
        echo ""
        log_success "Resource group '$RESOURCE_GROUP' has been completely deleted!"
    fi
}

# =============================================================================
# Parse Command Line Arguments
# =============================================================================

while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -f|--force)
            FORCE_DELETE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# =============================================================================
# Validation
# =============================================================================

if [ -z "$RESOURCE_GROUP" ]; then
    log_error "Resource group name is required."
    echo "Use: ./scripts/cleanup.sh --resource-group <rg-name>"
    echo "Use --help for more information."
    exit 1
fi

# =============================================================================
# Main Execution
# =============================================================================

echo -e "${BLUE}=== Azure ML Infrastructure Cleanup ===${NC}"
echo ""

validate_prerequisites
check_resource_group_exists
show_resource_summary
confirm_deletion
delete_resource_group
purge_soft_deleted_workspaces
wait_for_deletion

echo ""
log_success "Cleanup script completed successfully!"

if [ "$FORCE_DELETE" = false ]; then
    echo ""
    log_info "Next steps:"
    echo "  • Verify deletion completed: az group show --name '$RESOURCE_GROUP'"
    echo "  • Check your Azure portal to confirm resources are gone"
    echo "  • Review any remaining costs in Azure Cost Management"
fi