// The Fortress - Production Spoke VNet
// Deploys the production spoke and configures hub peering.
// Requires vnet-hub.bicep to be deployed first.
// Status: Planned

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Hub VNet resource ID - required for peering')
param hubVNetId string

@description('Hub VNet name - required for peering resource')
param hubVNetName string

@description('Log Analytics workspace resource ID for diagnostic settings')
param logAnalyticsWorkspaceId string

@description('Tags to apply to all resources')
param tags object = {
  environment: 'prod'
  project: 'the-fortress'
  owner: 'devon-booker'
  managedBy: 'bicep'
}

// ── VNet ──────────────────────────────────────────────────────────────────────

resource spokeProdVNet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-fortress-spoke-prod'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'ApplicationSubnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
          networkSecurityGroup: {
            id: appSubnetNsg.id
          }
          routeTable: {
            id: prodRouteTable.id
          }
        }
      }
      {
        name: 'DataSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          networkSecurityGroup: {
            id: dataSubnetNsg.id
          }
          routeTable: {
            id: prodRouteTable.id
          }
        }
      }
    ]
  }
}

// ── Route Table - Force Traffic Through Hub Firewall ──────────────────────────

resource prodRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-fortress-spoke-prod'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'Route-To-Hub-Firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          // TODO: Replace with actual Azure Firewall private IP after hub deployment
          nextHopIpAddress: '10.0.1.4'
        }
      }
    ]
  }
}

// ── NSGs ──────────────────────────────────────────────────────────────────────

resource appSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-fortress-spoke-prod-app'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-VNet-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          description: 'Allow inbound from VNet (hub controls what reaches here)'
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
        }
      }
    ]
  }
}

resource dataSubnetNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-fortress-spoke-prod-data'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-App-To-Data'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: '10.1.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '3306'
          description: 'Allow MySQL from ApplicationSubnet only'
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
        }
      }
    ]
  }
}

// ── VNet Peering: Spoke -> Hub ─────────────────────────────────────────────────

resource spokeProdToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  name: 'peer-spoke-prod-to-hub'
  parent: spokeProdVNet
  properties: {
    remoteVirtualNetwork: {
      id: hubVNetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: false // Set to true once VPN Gateway is deployed in hub
  }
}

// ── Diagnostic Settings ───────────────────────────────────────────────────────

resource spokeProdDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-vnet-spoke-prod'
  scope: spokeProdVNet
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

// ── Outputs ───────────────────────────────────────────────────────────────────

output spokeProdVNetId string = spokeProdVNet.id
output appSubnetId string = spokeProdVNet.properties.subnets[0].id
output dataSubnetId string = spokeProdVNet.properties.subnets[1].id
