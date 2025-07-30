#!/bin/bash

# Simple examples of how to use the cleanup script

echo "=== Azure ML Infrastructure Cleanup Examples ==="
echo ""

echo "1. Basic cleanup with confirmation prompts:"
echo "   ./scripts/cleanup.sh --resource-group rg-ml-dev"
echo ""

echo "2. Force cleanup without confirmation (DANGEROUS):"
echo "   ./scripts/cleanup.sh -g rg-ml-prod --force"
echo ""

echo "3. Get help and see all options:"
echo "   ./scripts/cleanup.sh --help"
echo ""

echo "4. Check if a resource group exists before cleanup:"
echo "   az group show --name rg-ml-dev"
echo ""

echo "5. Monitor deletion progress manually:"
echo "   az group show --name rg-ml-dev"
echo "   # Command will fail when deletion is complete"
echo ""

echo "=== Safety Reminders ==="
echo "• Always double-check the resource group name"
echo "• Use --force only in automation scenarios"
echo "• Consider exporting important data before deletion"
echo "• Verify deletion completion in Azure portal"