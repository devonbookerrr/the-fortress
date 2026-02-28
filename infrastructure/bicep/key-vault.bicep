// The Fortress - Key Vault
// Deploys Key Vault with RBAC authorization, private endpoint, and diagnostic settings.
// Status: Planned

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Environment tag value')
@allowed(['prod', 'dev'])
param environment string = 'prod'

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Subnet resource ID for private endpoint')
param privateEndpointSubnetId string

@description('Tags to apply to all resources')
param tags object = {
  environment: environment
  project: 'the-fortress'
  owner: 'devon-booker'
  managedBy: 'bicep'
}

// ── Key Vault ─────────────────────────────────────────────────────────────────

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-fortress-${environment}-001'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true       // RBAC model - not legacy access policies
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'     // Private endpoint only
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// ── Private Endpoint ──────────────────────────────────────────────────────────

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'pe-kv-fortress-${environment}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'kv-fortress-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: ['vault']
        }
      }
    ]
  }
}

// ── Diagnostic Settings ───────────────────────────────────────────────────────

resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-kv-fortress'
  scope: keyVault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 180
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
