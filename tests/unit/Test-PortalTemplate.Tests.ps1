#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
& (Join-Path $root 'scripts/powershell/Build-PortalTemplate.ps1') -Check
$template = Get-Content (Join-Path $root 'infra/portal/azuredeploy.json') -Raw | ConvertFrom-Json -AsHashtable
$script:checks = 0
function Assert-True {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:checks++
    Write-Output "PASS: $Name"
}
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
foreach ($name in @('agentName', 'location', 'applicationInsightsResourceGroupName', 'applicationInsightsName', 'modelProvider', 'modelName')) {
    Assert-True (-not $template.parameters[$name].ContainsKey('defaultValue')) "explicit $name"
}
$allResources = @(Get-Resources $template)
$resources = @($allResources | Where-Object { $_ -is [System.Collections.IDictionary] })
$agents = @($resources | Where-Object type -EQ 'Microsoft.App/agents')
Assert-True ($agents.Count -eq 1) 'one agent'
Assert-True ($agents[0].properties.actionConfiguration.mode -eq 'Review') 'Review preserved'
Assert-True ($agents[0].properties.actionConfiguration.accessLevel -eq 'Low') 'Low preserved'
Assert-True ($agents[0].apiVersion -eq '2026-01-01') 'stable agent contract preserved'
Assert-True (@($resources | Where-Object type -EQ 'Microsoft.Insights/components').Count -eq 0) 'monitoring reused, not created'
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