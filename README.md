# Azure Machine Learning Infrastructure as Code

An infrastructure-as-code repository for deploying Azure Machine Learning workspace with secure networking, including a virtual network, Windows jumpbox, and private endpoints.

## Architecture Overview

This repository deploys a comprehensive Azure Machine Learning environment with the following components:

- **🌐 Virtual Network**: Segmented network with dedicated subnets
- **🖥️ Windows Jumpbox**: Secure access point with RDP connectivity
- **🤖 Azure ML Workspace**: Machine learning workspace with private networking
- **🔒 Private Endpoints**: Secure connectivity for Storage, Key Vault, and ML services
- **📊 Monitoring**: Application Insights and Log Analytics integration
- **🔐 Security**: Key Vault for secrets management with RBAC

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed ([Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
2. **Azure subscription** with appropriate permissions
3. **Contributor or Owner** role on the target subscription/resource group

## Quick Start

### 1. Login to Azure
```bash
az login
```

### 2. Clone and Navigate
```bash
git clone <repository-url>
cd azure-machine-learning-il5
```

### 3. Deploy Infrastructure
```bash
# Basic deployment
./scripts/deploy.sh -g rg-ml-dev -p "YourSecurePassword123!"
```

## Deployment Options

### Basic Deployment
Deploy with minimal configuration to a new or existing resource group:
```bash
./scripts/deploy.sh \
  --resource-group rg-ml-dev \
  --admin-password "YourSecurePassword123!"
```

### Production Deployment
Deploy with custom environment settings:
```bash
./scripts/deploy.sh \
  --resource-group rg-ml-prod \
  --environment prod \
  --location westus2 \
  --admin-username prodadmin \
  --admin-password "YourSecurePassword123!" \
  --vm-size Standard_D4s_v3
```

### Validation and Preview

#### Dry Run (Validate Template)
Test your deployment without creating resources:
```bash
./scripts/deploy.sh \
  --resource-group rg-ml-dev \
  --admin-password "YourSecurePassword123!" \
  --dry-run
```

#### What-If Analysis
Preview what resources will be created or modified:
```bash
./scripts/deploy.sh \
  --resource-group rg-ml-dev \
  --admin-password "YourSecurePassword123!" \
  --what-if
```

## Script Parameters

| Parameter | Short | Required | Default | Description |
|-----------|-------|----------|---------|-------------|
| `--help` | `-h` | No | - | Show help message and exit |
| `--environment` | `-e` | No | `azml-demo` | Environment name prefix for resources |
| `--location` | `-l` | No | `eastus` | Azure region for deployment |
| `--resource-group` | `-g` | **Yes** | - | Target resource group name |
| `--admin-username` | `-u` | No | `azureadmin` | VM administrator username |
| `--admin-password` | `-p` | **Yes** | - | VM administrator password |
| `--vm-size` | `-s` | No | `Standard_D2s_v3` | Virtual machine size |
| `--dry-run` | - | No | - | Validate template without deploying |
| `--what-if` | - | No | - | Show deployment preview |

## Post-Deployment Access

After successful deployment, you'll receive connection details:

### 1. Jumpbox Access
Connect to your Windows jumpbox via RDP:
- **Server**: `[jumpbox-fqdn]` (provided in deployment output)
- **Username**: Your specified admin username
- **Port**: 3389

### 2. Azure ML Studio
Access your machine learning workspace:
- **URL**: https://ml.azure.com
- **Workspace**: `[workspace-name]` (provided in deployment output)

### 3. Secure Architecture
- All ML services are accessible only through private endpoints
- The jumpbox provides secure access to your private Azure ML workspace
- Storage and Key Vault are configured with private networking

## File Structure

```
├── infra/
│   ├── main.bicep                    # Main orchestration template
│   ├── main.parameters.json          # Sample parameters file
│   ├── abbreviations.json            # Azure resource naming conventions
│   └── modules/
│       ├── network.bicep             # Virtual network and security groups
│       ├── jumpbox.bicep             # Windows VM jumpbox
│       ├── storage.bicep             # Storage, Key Vault, monitoring
│       └── azure-machine-learning.bicep  # ML workspace and private endpoints
├── scripts/
│   ├── deploy.sh                     # Main deployment script
│   ├── examples.sh                   # Usage examples
│   ├── cleanup.sh                    # Resource group cleanup script
│   └── cleanup-examples.sh           # Cleanup usage examples
└── README.md                         # This file
```

## Infrastructure Components

### 🏗️ **Modular Architecture**
The infrastructure is organized into reusable Bicep modules:

- **`network.bicep`**: Virtual network, subnets, and network security groups
- **`jumpbox.bicep`**: Windows VM with public IP and RDP access
- **`storage.bicep`**: Storage account, Key Vault, Application Insights, Log Analytics
- **`azure-machine-learning.bicep`**: ML workspace and all private endpoints
- **`main.bicep`**: Orchestrates all modules with proper dependencies

### Networking
- **Virtual Network**: `10.0.0.0/16` address space
- **Jumpbox Subnet**: `10.0.1.0/24` for Windows VM
- **Private Endpoint Subnet**: `10.0.2.0/24` for secure connections
- **Network Security Groups**: Configured for secure access

### Compute
- **Windows Server 2022**: Latest Azure edition
- **Premium SSD**: For optimal performance
- **Managed Identity**: For secure Azure service access

### Machine Learning
- **Azure ML Workspace**: With system-assigned managed identity
- **Private Endpoints**: For secure connectivity
- **Managed Network**: Isolated environment for ML workloads

### Supporting Services
- **Storage Account**: For ML artifacts and data
- **Key Vault**: For secrets and certificate management
- **Application Insights**: For monitoring and telemetry
- **Log Analytics**: For centralized logging

## Security Features

- ✅ **Private Networking**: All ML services use private endpoints
- ✅ **Network Isolation**: Segmented subnets with security groups
- ✅ **Managed Identities**: No stored credentials
- ✅ **RBAC**: Role-based access control enabled
- ✅ **TLS 1.2**: Enforced for all connections
- ✅ **Secure Storage**: Public access disabled

## Troubleshooting

### Common Issues

1. **Authentication Error**
   ```bash
   # Solution: Login to Azure
   az login
   ```

2. **Insufficient Permissions**
   ```bash
   # Check your role assignments
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

3. **Resource Group Not Found**
   - The script will automatically create the resource group if it doesn't exist
   - Ensure you have Contributor rights on the subscription

4. **Password Requirements**
   - Must be 8-123 characters long
   - Must contain 3 of: lowercase, uppercase, numbers, special characters

### Getting Help

View all available options:
```bash
./scripts/deploy.sh --help
```

View usage examples:
```bash
View usage examples:
```bash
./scripts/examples.sh
```

## Cleanup

To completely remove all deployed resources:

### Safe Cleanup (Recommended)
```bash
# Interactive cleanup with confirmation
./scripts/cleanup.sh --resource-group rg-ml-dev
```

### Force Cleanup (Use with Caution)
```bash
# Skip confirmations - use only for automation
./scripts/cleanup.sh -g rg-ml-dev --force
```

### Cleanup Examples
```bash
# View cleanup usage examples
./scripts/cleanup-examples.sh

# Get cleanup help
./scripts/cleanup.sh --help
```

## Support
```

## Next Steps

After deployment:

1. **Connect to Jumpbox**: Use RDP to access your Windows VM
2. **Install Tools**: Install Azure ML SDK, Python, or other development tools
3. **Access ML Studio**: Navigate to https://ml.azure.com to start building models
4. **Configure Networking**: Set up additional private endpoints if needed
5. **Set Up CI/CD**: Integrate with Azure DevOps or GitHub Actions

## Support

For issues or questions:
- Check the [Azure Machine Learning documentation](https://docs.microsoft.com/en-us/azure/machine-learning/)
- Review [Azure Bicep documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- Open an issue in this repository  
