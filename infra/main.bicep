// Azure Machine Learning Infrastructure with Virtual Network and Jumpbox
// This template deploys a secure Azure ML workspace with private endpoints,
// a virtual network, and a Windows jumpbox VM for secure access

targetScope = 'resourceGroup'

// ========================================
// Parameters
// ========================================

@description('Environment name prefix for all resources')
param environmentName string = 'azml-demo'

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Administrator username for the jumpbox VM')
param adminUsername string = 'azureadmin'

@description('Administrator password for the jumpbox VM')
@secure()
param adminPassword string

@description('Size of the jumpbox VM')
param vmSize string = 'Standard_D2s_v3'

// Resource naming with resource token for uniqueness
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var abbrs = loadJsonContent('abbreviations.json')

// ========================================
// Network Module
// ========================================

module network 'modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
    abbrs: abbrs
  }
}

// ========================================
// Storage and Supporting Services Module
// ========================================

module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
  }
}

// ========================================
// Jumpbox Module
// ========================================

module jumpbox 'modules/jumpbox.bicep' = {
  name: 'jumpbox-deployment'
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
    abbrs: abbrs
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    jumpboxSubnetId: network.outputs.jumpboxSubnetId
  }
}

// ========================================
// Azure Machine Learning Module
// ========================================

module azureML 'modules/azure-machine-learning.bicep' = {
  name: 'azureml-deployment'
  params: {
    environmentName: environmentName
    location: location
    resourceToken: resourceToken
    abbrs: abbrs
    storageAccountId: storage.outputs.storageAccountId
    keyVaultId: storage.outputs.keyVaultId
    appInsightsId: storage.outputs.appInsightsId
    privateEndpointSubnetId: network.outputs.privateEndpointSubnetId
  }
}

// ========================================
// Outputs
// ========================================

@description('The name of the resource group')
output resourceGroupName string = resourceGroup().name

@description('The name of the virtual network')
output virtualNetworkName string = network.outputs.vnetName

@description('The name of the jumpbox virtual machine')
output jumpboxVmName string = jumpbox.outputs.vmName

@description('The public IP address of the jumpbox')
output jumpboxPublicIp string = jumpbox.outputs.publicIpAddress

@description('The FQDN of the jumpbox')
output jumpboxFqdn string = jumpbox.outputs.fqdn

@description('The name of the Azure ML workspace')
output mlWorkspaceName string = azureML.outputs.mlWorkspaceName

@description('The ID of the Azure ML workspace')
output mlWorkspaceId string = azureML.outputs.mlWorkspaceId

@description('The name of the storage account')
output storageAccountName string = storage.outputs.storageAccountName

@description('The name of the key vault')
output keyVaultName string = storage.outputs.keyVaultName

@description('The name of the Application Insights component')
output appInsightsName string = storage.outputs.appInsightsName

@description('Connection information for accessing the jumpbox')
output connectionInfo object = {
  jumpboxFqdn: jumpbox.outputs.fqdn
  adminUsername: adminUsername
  rdpPort: 3389
  instructions: 'Connect via RDP using the FQDN and credentials provided'
}
