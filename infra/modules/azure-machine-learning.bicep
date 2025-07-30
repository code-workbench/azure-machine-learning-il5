// Azure Machine Learning Module
// This module creates the ML workspace and private endpoints

@description('Environment name prefix for all resources')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Resource token for unique naming')
param resourceToken string

@description('Abbreviations for resource naming')
param abbrs object

@description('The resource ID of the storage account')
param storageAccountId string

@description('The resource ID of the key vault')
param keyVaultId string

@description('The resource ID of the Application Insights component')
param appInsightsId string

@description('The resource ID of the private endpoint subnet')
param privateEndpointSubnetId string

// ========================================
// Variables
// ========================================

var mlWorkspaceName = '${abbrs.machineLearningServicesWorkspaces}${environmentName}-${resourceToken}'
var peStorageName = '${abbrs.networkPrivateEndpoints}storage-${resourceToken}'
var peKeyVaultName = '${abbrs.networkPrivateEndpoints}kv-${resourceToken}'
var peMLWorkspaceName = '${abbrs.networkPrivateEndpoints}ml-${resourceToken}'

// ========================================
// Azure Machine Learning Workspace
// ========================================

resource mlWorkspace 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: mlWorkspaceName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: '${environmentName} ML Workspace'
    description: 'Azure Machine Learning workspace with private networking'
    storageAccount: storageAccountId
    keyVault: keyVaultId
    applicationInsights: appInsightsId
    publicNetworkAccess: 'Disabled'
    managedNetwork: {
      isolationMode: 'AllowOnlyApprovedOutbound'
      outboundRules: {}
    }
  }
}

// ========================================
// Private Endpoints
// ========================================

// Private endpoint for Storage Account (blob)
resource peStorageBlob 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${peStorageName}-blob'
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-blob-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: ['blob']
        }
      }
    ]
  }
}

// Private endpoint for Storage Account (file)
resource peStorageFile 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${peStorageName}-file'
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-file-connection'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: ['file']
        }
      }
    ]
  }
}

// Private endpoint for Key Vault
resource peKeyVault 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: peKeyVaultName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'keyvault-connection'
        properties: {
          privateLinkServiceId: keyVaultId
          groupIds: ['vault']
        }
      }
    ]
  }
}

// Private endpoint for ML Workspace
resource peMLWorkspace 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: peMLWorkspaceName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'ml-workspace-connection'
        properties: {
          privateLinkServiceId: mlWorkspace.id
          groupIds: ['amlworkspace']
        }
      }
    ]
  }
}

// ========================================
// Outputs
// ========================================

@description('The name of the Azure ML workspace')
output mlWorkspaceName string = mlWorkspace.name

@description('The resource ID of the Azure ML workspace')
output mlWorkspaceId string = mlWorkspace.id

@description('The principal ID of the ML workspace managed identity')
output mlWorkspacePrincipalId string = mlWorkspace.identity.principalId
