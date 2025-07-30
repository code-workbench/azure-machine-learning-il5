// Network Infrastructure Module
// This module creates the virtual network, subnets, and network security groups

@description('Environment name prefix for all resources')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Resource token for unique naming')
param resourceToken string

@description('Abbreviations for resource naming')
param abbrs object

// ========================================
// Variables
// ========================================

var vnetName = '${abbrs.networkVirtualNetworks}${environmentName}-${resourceToken}'
var jumpboxSubnetName = 'jumpbox-subnet'
var privateEndpointSubnetName = 'private-endpoint-subnet'
var nsgJumpboxName = '${abbrs.networkNetworkSecurityGroups}jumpbox-${resourceToken}'
var nsgPrivateEndpointName = '${abbrs.networkNetworkSecurityGroups}pe-${resourceToken}'

// ========================================
// Network Security Groups
// ========================================

// NSG for jumpbox subnet
resource nsgJumpbox 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgJumpboxName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
          description: 'Allow RDP access to jumpbox'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Outbound'
          description: 'Allow HTTPS outbound'
        }
      }
    ]
  }
}

// NSG for private endpoint subnet
resource nsgPrivateEndpoint 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgPrivateEndpointName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    securityRules: []
  }
}

// ========================================
// Virtual Network
// ========================================

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: jumpboxSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgJumpbox.id
          }
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsgPrivateEndpoint.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// ========================================
// Outputs
// ========================================

@description('The resource ID of the virtual network')
output vnetId string = vnet.id

@description('The name of the virtual network')
output vnetName string = vnet.name

@description('The resource ID of the jumpbox subnet')
output jumpboxSubnetId string = '${vnet.id}/subnets/${jumpboxSubnetName}'

@description('The resource ID of the private endpoint subnet')
output privateEndpointSubnetId string = '${vnet.id}/subnets/${privateEndpointSubnetName}'

@description('The name of the jumpbox subnet')
output jumpboxSubnetName string = jumpboxSubnetName

@description('The name of the private endpoint subnet')
output privateEndpointSubnetName string = privateEndpointSubnetName
