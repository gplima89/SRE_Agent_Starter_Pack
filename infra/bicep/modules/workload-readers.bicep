targetScope = 'resourceGroup'

@description('Exact SAMI or UAMI object ID to grant read roles to at this workload RG only.')
@minLength(36)
@maxLength(36)
param principalId string

var readerRoleId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
var logReaderRoleId = '73c42c96-874c-492b-b04d-ab87d138a893'

module reader 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.0' = {
  name: 'sre-workload-reader'
  params: {
    name: guid(resourceGroup().id, principalId, readerRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerRoleId)
    enableTelemetry: false
  }
}

module logReader 'br/public:avm/res/authorization/role-assignment/rg-scope:0.1.0' = {
  name: 'sre-workload-log-reader'
  params: {
    name: guid(resourceGroup().id, principalId, logReaderRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionIdOrName: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logReaderRoleId)
    enableTelemetry: false
  }
}

output roleAssignmentIds array = [reader.outputs.resourceId, logReader.outputs.resourceId]