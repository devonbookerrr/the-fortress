// The Fortress - Log Analytics Workspace
// Central workspace for all Azure, M365, and Linux telemetry.
// Deploy this first - its resource ID is required by all other Bicep templates.
// Status: Planned

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Data retention in days (30-730)')
@minValue(30)
@maxValue(730)
param retentionDays int = 90

@description('Tags to apply to all resources')
param tags object = {
  environment: 'prod'
  project: 'the-fortress'
  owner: 'devon-booker'
  managedBy: 'bicep'
}

// ── Log Analytics Workspace ───────────────────────────────────────────────────

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-fortress-prod-001'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output workspaceId string = logAnalyticsWorkspace.id
output workspaceName string = logAnalyticsWorkspace.name
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
