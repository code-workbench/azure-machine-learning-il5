// Storage and Supporting Services Module
// This module creates storage account, key vault, application insights, and log analytics

@description('Environment name prefix for all resources')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Resource token for unique naming')
param resourceToken string

// ========================================
// Variables
// ========================================

// Ensure minimum length requirements for resource names
// Storage account name must be 3-24 characters, alphanumeric only
var storageAccountName = take('stml${replace(environmentName, '-', '')}${resourceToken}', 24)
var keyVaultName = take('kv-${environmentName}-${resourceToken}', 24)
var appInsightsName = 'appi-${environmentName}-${resourceToken}'
var logAnalyticsName = 'log-${environmentName}-${resourceToken}'

// ========================================
// Log Analytics Workspace
// ========================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ========================================
// Application Insights
// ========================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// ========================================
// Key Vault
// ========================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// ========================================
// Storage Account
// ========================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// ========================================
// Outputs
// ========================================

@description('The resource ID of the storage account')
output storageAccountId string = storageAccount.id

@description('The name of the storage account')
output storageAccountName string = storageAccount.name

@description('The resource ID of the key vault')
output keyVaultId string = keyVault.id

@description('The name of the key vault')
output keyVaultName string = keyVault.name

@description('The resource ID of the Application Insights component')
output appInsightsId string = appInsights.id

@description('The name of the Application Insights component')
output appInsightsName string = appInsights.name

@description('The resource ID of the Log Analytics workspace')
output logAnalyticsId string = logAnalytics.id

@description('The name of the Log Analytics workspace')
output logAnalyticsName string = logAnalytics.name
