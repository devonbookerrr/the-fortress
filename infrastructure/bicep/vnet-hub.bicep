// The Fortress - Hub VNet
// Deploys the hub VNet with Azure Firewall, DNS, and Gateway subnets.
// Deploy this first before any spoke VNets.
// Status: Planned

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment tag value')
@allowed(['prod', 'dev', 'staging'])
param environment string = 'prod'

@description('Hub VNet address space')
param hubAddressSpace string = '10.0.0.0/16'

@description('Log Analytics workspace resource ID for diagnostic settings')
param logAnalyticsWorkspaceId string

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  project: 'the-fortress'
  owner: 'devon-booker'
  managedBy: 'bicep'
}

// ── VNet ─────────────────────────────────────────────────────────────────────

resource hubVNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-fortress-hub-${environment}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [hubAddressSpace]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
          // Azure Firewall subnet cannot have an NSG
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.2.0/27'
          // Gateway subnet cannot have an NSG
        }
      }
      {
        name: 'ManagementSubnet'
        properties: {
          addressPrefix: '10.0.3.0/28'
          networkSecurityGroup: {
            id: mgmtNsg.id
          }
        }
      }
    ]
  }
}

// ── NSG: Management Subnet ────────────────────────────────────────────────────

resource mgmtNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-fortress-hub-mgmt-${environment}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          description: 'Allow SSH from within VNet only'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Deny all other inbound traffic'
        }
      }
    ]
  }
}

// ── Diagnostic Settings ───────────────────────────────────────────────────────

resource hubVNetDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-vnet-hub'
  scope: hubVNet
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource mgmtNsgDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-nsg-hub-mgmt'
  scope: mgmtNsg
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output hubVNetId string = hubVNet.id
output hubVNetName string = hubVNet.name
output firewallSubnetId string = hubVNet.properties.subnets[0].id
output gatewaySubnetId string = hubVNet.properties.subnets[1].id
output managementSubnetId string = hubVNet.properties.subnets[2].id
