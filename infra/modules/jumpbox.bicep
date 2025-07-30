// Jumpbox VM Module
// This module creates the Windows jumpbox virtual machine with public IP and network interface

@description('Environment name prefix for all resources')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Resource token for unique naming')
param resourceToken string

@description('Abbreviations for resource naming')
param abbrs object

@description('Administrator username for the jumpbox VM')
param adminUsername string

@description('Administrator password for the jumpbox VM')
@secure()
param adminPassword string

@description('Size of the jumpbox VM')
param vmSize string

@description('The resource ID of the jumpbox subnet')
param jumpboxSubnetId string

// ========================================
// Variables
// ========================================

var vmName = '${abbrs.computeVirtualMachines}jumpbox-${resourceToken}'
var nicName = '${abbrs.networkNetworkInterfaces}jumpbox-${resourceToken}'
var pipName = '${abbrs.networkPublicIPAddresses}jumpbox-${resourceToken}'

// ========================================
// Public IP for Jumpbox
// ========================================

resource pip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: pipName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${vmName}-${resourceToken}'
    }
  }
}

// ========================================
// Network Interface for Jumpbox
// ========================================

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: jumpboxSubnetId
          }
        }
      }
    ]
  }
}

// ========================================
// Windows Virtual Machine (Jumpbox)
// ========================================

resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter-azure-edition'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// ========================================
// Outputs
// ========================================

@description('The name of the jumpbox virtual machine')
output vmName string = vm.name

@description('The resource ID of the jumpbox virtual machine')
output vmId string = vm.id

@description('The public IP address of the jumpbox')
output publicIpAddress string = pip.properties.ipAddress

@description('The FQDN of the jumpbox')
output fqdn string = pip.properties.dnsSettings.fqdn

@description('The admin username for the jumpbox')
output adminUsername string = adminUsername
