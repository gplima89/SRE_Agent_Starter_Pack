#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $root 'scripts/powershell/Build-PortalTemplate.ps1') -Check
$template = Get-Content (Join-Path $root 'infra/portal/azuredeploy.json') -Raw | ConvertFrom-Json -AsHashtable
$script:checks = 0
# Throws on a failed condition; otherwise counts and reports the named check.
function Assert-True {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:checks++
    Write-Output "PASS: $Name"
}
# Walks array or dictionary resources and embedded templates, rejecting remote template dependencies.
function Get-Resources {
    param([hashtable]$Template)
    $direct = if ($Template.resources -is [System.Collections.IDictionary]) { $Template.resources.Values } else { $Template.resources }
    foreach ($resource in $direct) {
        $resource
        if ($resource.type -eq 'Microsoft.Resources/deployments') {
            Assert-True (-not $resource.properties.ContainsKey('templateLink')) 'embedded module, no remote template dependency'
            Get-Resources $resource.properties.template
        }
    }
}
Assert-True ($template.'$schema' -eq 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#') 'resource-group Portal scope'
Assert-True ($template.parameters.environment.defaultValue -eq 'dev') 'dev default'
Assert-True (-not $template.parameters.assignWorkloadReaderRoles.defaultValue) 'reader opt-in defaults false'
Assert-True ($template.parameters.workloadResourceGroupName.defaultValue -eq '') 'workload scope defaults empty'
Assert-True (-not $template.parameters.ContainsKey('tags')) 'no raw JSON tag input'
foreach ($name in $template.parameters.Keys) {
    Assert-True (-not [string]::IsNullOrWhiteSpace($template.parameters[$name].metadata.description)) "help for $name"
    Assert-True ($name -notmatch 'secret|token|password|connectionString|tenantId|subscriptionId') "no secret or redundant target input $name"
}
foreach ($name in @('agentName', 'location', 'modelProvider', 'modelName')) {
    Assert-True (-not $template.parameters[$name].ContainsKey('defaultValue')) "explicit $name"
}
$modelHelp = $template.parameters.modelName.metadata.description
foreach ($example in @('gpt-5', 'claude-opus-4-5', 'claude-sonnet-4-5')) {
    Assert-True ($modelHelp.Contains($example)) "documented model-name example: $example"
}
Assert-True ($modelHelp.Contains('none is guaranteed in every region')) 'model examples do not promise universal availability'
Assert-True ($template.parameters.monitoringMode.defaultValue -eq 'Create new') 'create monitoring by default'
Assert-True (($template.parameters.monitoringMode.allowedValues -join ',') -eq 'Create new,Use existing') 'only create or reuse monitoring modes'
Assert-True ($template.variables.createMonitoring -ceq "[equals(parameters('monitoringMode'), 'Create new')]") 'reuse mode disables monitoring creation'
foreach ($name in @('applicationInsightsResourceGroupName', 'applicationInsightsName')) {
    Assert-True ($template.parameters[$name].defaultValue -eq '') "no existing telemetry input needed for create mode: $name"
}
$allResources = @(Get-Resources $template)
$resources = @($allResources | Where-Object { $_ -is [System.Collections.IDictionary] })
$agents = @($resources | Where-Object type -EQ 'Microsoft.App/agents')
Assert-True ($agents.Count -eq 1) 'one agent'
Assert-True ($agents[0].properties.actionConfiguration.mode -eq 'Review') 'Review preserved'
Assert-True ($agents[0].properties.actionConfiguration.accessLevel -eq 'Low') 'Low preserved'
Assert-True ($agents[0].apiVersion -eq '2026-01-01') 'stable agent contract preserved'
$components = @($resources | Where-Object type -EQ 'Microsoft.Insights/components')
$workspaces = @($resources | Where-Object type -EQ 'Microsoft.OperationalInsights/workspaces')
Assert-True ($components.Count -eq 1 -and $workspaces.Count -eq 1) 'one conditional component and workspace'
$component = $components[0]
$workspace = $workspaces[0]
$workspaceId = "[resourceId('Microsoft.OperationalInsights/workspaces', format('{0}-logs', parameters('agentName')))]"
$componentId = "[resourceId('Microsoft.Insights/components', format('{0}-appi', parameters('agentName')))]"
foreach ($resource in @($component, $workspace)) {
    Assert-True ($resource.condition -ceq "[variables('createMonitoring')]") "create only, no reuse writes: $($resource.type)"
    Assert-True ($resource.location -ceq "[parameters('location')]") "explicit monitoring location: $($resource.type)"
    Assert-True ($resource.tags -ceq "[variables('resourceTags')]") "shared ownership tags: $($resource.type)"
}
Assert-True ($component.apiVersion -eq '2020-02-02' -and $workspace.apiVersion -eq '2025-07-01') 'pinned stable monitoring contracts'
Assert-True ($workspace.name -ceq "[format('{0}-logs', parameters('agentName'))]") 'derived workspace name'
Assert-True ($component.name -ceq "[format('{0}-appi', parameters('agentName'))]") 'derived component name'
Assert-True ($workspace.properties.sku.name -eq 'PerGB2018') 'pay-as-you-go workspace'
Assert-True ($workspace.properties.retentionInDays -eq 30) 'workspace default retention 30 days, not table purge guarantee'
Assert-True ($workspace.properties.features.enableLogAccessUsingOnlyResourcePermissions) 'resource-context log access'
Assert-True (-not $component.properties.DisableIpMasking) 'IP masking preserved'
Assert-True ($component.properties.WorkspaceResourceId -ceq $workspaceId) 'workspace-based component linkage'
Assert-True ($component.properties.IngestionMode -eq 'LogAnalytics') 'workspace ingestion mode'
Assert-True ($component.dependsOn -contains $workspaceId) 'component waits for workspace'
$foundation = @($template.resources | Where-Object name -EQ 'sre-foundation')[0]
Assert-True ($foundation.dependsOn -contains $componentId) 'foundation waits for new component'
Assert-True ($foundation.properties.mode -eq 'Incremental') 'reuse deployments do not delete monitoring'
Assert-True ($foundation.properties.parameters.applicationInsightsName -ceq "[if(variables('createMonitoring'), createObject('value', format('{0}-appi', parameters('agentName'))), createObject('value', parameters('applicationInsightsName')))]") 'create name or existing name passed lazily'
Assert-True ($foundation.properties.parameters.applicationInsightsResourceGroupName -ceq "[if(variables('createMonitoring'), createObject('value', resourceGroup().name), createObject('value', parameters('applicationInsightsResourceGroupName')))]") 'create group or existing group passed lazily'
foreach ($name in @('applicationInsightsName', 'applicationInsightsResourceGroupName')) {
    Assert-True ($foundation.properties.template.parameters[$name].minLength -eq 1) "foundation rejects blank reuse input: $name"
}
Assert-True ($template.outputs.ContainsKey('applicationInsightsId')) 'mode-neutral monitoring ID output'
Assert-True (-not $template.outputs.ContainsKey('reusedApplicationInsightsId')) 'Portal output does not mislabel created telemetry'
Assert-True (@($resources | Where-Object { $_.type -like 'Microsoft.App/agents/*' }).Count -eq 0) 'no extra agent configuration'
foreach ($name in $template.outputs.Keys) {
    Assert-True ($name -notmatch 'secret|key|token|connectionString') "non-sensitive output $name"
}
$readme = Get-Content (Join-Path $root 'README.md') -Raw
$match = [regex]::Match($readme, '\[!\[Deploy to Azure\]\(https://aka.ms/deploytoazurebutton\)\]\(https://portal.azure.com/#create/Microsoft.Template/uri/([^\)]+)\)')
Assert-True $match.Success 'official button format'
$rawUrl = [uri]::UnescapeDataString($match.Groups[1].Value)
Assert-True ($rawUrl -match '^https://raw\.githubusercontent\.com/gplima89/SRE_Agent_Starter_Pack/(main|[0-9a-f]{40})/infra/portal/azuredeploy\.json$') 'button targets correct public ARM artifact'
Write-Output "PASS: $script:checks Portal checks; live deployment readiness NOT CHECKED."