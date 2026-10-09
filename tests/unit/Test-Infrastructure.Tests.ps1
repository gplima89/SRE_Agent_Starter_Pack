#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$templatePath = Join-Path $root 'infra/bicep/main.bicep'
$output = & az bicep build --file $templatePath --stdout --only-show-errors
if ($LASTEXITCODE -ne 0) { throw 'Bicep compilation failed.' }
$template = ($output -join "`n") | ConvertFrom-Json -AsHashtable
$script:checks = 0
function Assert-True {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:checks++
    Write-Output "PASS: $Name"
}
function Get-DirectResources {
    param([hashtable]$Template)
    if ($Template.resources -is [System.Collections.IDictionary]) {
        $Template.resources.Values
    } else {
        $Template.resources
    }
}
function Get-NestedResources {
    param([hashtable]$Template)
    foreach ($resource in (Get-DirectResources -Template $Template)) {
        $resource
        if ($resource.type -eq 'Microsoft.Resources/deployments') {
            Get-NestedResources -Template $resource.properties.template
        }
    }
}
$resources = @(Get-NestedResources -Template $template)
$agents = @($resources | Where-Object type -EQ 'Microsoft.App/agents')
Assert-True ($agents.Count -eq 1) 'exactly one agent'
$agent = $agents[0]
Assert-True ($agent.apiVersion -eq '2026-01-01') 'versioned stable ARM contract'
Assert-True ($agent.properties.actionConfiguration.mode -eq 'Review') 'Review hardcoded'
Assert-True ($agent.properties.actionConfiguration.accessLevel -eq 'Low') 'Low access hardcoded'
Assert-True ($agent.properties.upgradeChannel -eq 'Stable') 'Stable upgrade channel'
Assert-True ($agent.identity.type -eq 'SystemAssigned, UserAssigned') 'SAMI and UAMI configured'
Assert-True (-not $template.parameters.assignWorkloadReaderRoles.defaultValue) 'RBAC opt-in defaults false'
Assert-True ($template.parameters.modelProvider.minLength -eq 1 -and -not $template.parameters.modelProvider.ContainsKey('defaultValue')) 'provider requires explicit input'
Assert-True ($template.parameters.modelName.minLength -eq 1 -and -not $template.parameters.modelName.ContainsKey('defaultValue')) 'model requires explicit input'
$agentDeployment = @(Get-DirectResources -Template $template | Where-Object {
    $_.type -eq 'Microsoft.Resources/deployments' -and
    @(Get-DirectResources -Template $_.properties.template | Where-Object type -EQ 'Microsoft.App/agents').Count -gt 0
})[0]
Assert-True ($agentDeployment.properties.template.parameters.applicationInsightsConnectionString.type -eq 'secureString') 'secure telemetry module parameter'
Assert-True ($agentDeployment.properties.template.parameters.workloadResourceGroupIds.maxLength -eq 1) 'one workload scope maximum'
Assert-True (@($resources | Where-Object { $_.type -like 'Microsoft.App/agents/*' }).Count -eq 0) 'no agent configuration sub-resources or automation'
foreach ($property in @('experimentalSettings', 'monthlyAgentUnitLimit', 'sandboxConfiguration', 'vnetConfiguration', 'incidentManagementConfiguration')) {
    Assert-True (-not $agent.properties.ContainsKey($property)) "no unverified property $property"
}
$allowedRoleIds = @('acdd72a7-3385-48ef-bd42-f606fba81ae7', '73c42c96-874c-492b-b04d-ab87d138a893')
$readerDeployments = @(Get-DirectResources -Template $template | Where-Object name -In @('sre-uami-readers', 'sre-sami-readers'))
Assert-True ($readerDeployments.Count -eq 2) 'both identity role paths explicit'
foreach ($deployment in $readerDeployments) {
    Assert-True ($deployment.condition -match 'assignWorkloadReaderRoles') 'identity RBAC obeys opt-in'
    Assert-True ($deployment.ContainsKey('resourceGroup') -and -not $deployment.ContainsKey('subscriptionId')) 'role module uses workload RG in current subscription'
    foreach ($roleDeployment in (Get-DirectResources -Template $deployment.properties.template)) {
        $roleExpression = $roleDeployment.properties.parameters.roleDefinitionIdOrName.value
        $variableMatch = [regex]::Match($roleExpression, "variables\('([^']+)'\)")
        Assert-True ($variableMatch.Success) 'role input references a compiled role variable'
        $roleId = $deployment.properties.template.variables[$variableMatch.Groups[1].Value]
        Assert-True ($roleId -in $allowedRoleIds) 'role input is reader allowlist only'
    }
}
foreach ($outputName in $template.outputs.Keys) {
    Assert-True ($outputName -notmatch 'key|secret|token|connectionString|endpoint') "non-sensitive root output $outputName"
}
$environmentNames = @('SRE_AGENT_LOCATION', 'SRE_APPINSIGHTS_RESOURCE_GROUP', 'SRE_APPINSIGHTS_NAME', 'SRE_MODEL_PROVIDER', 'SRE_MODEL_NAME')
$savedValues = @{}
foreach ($name in $environmentNames) { $savedValues[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $fixtureValues = @('eastus2', 'rg-example-telemetry', 'ai-example', 'schema-test-provider', 'schema-test-model')
    for ($index = 0; $index -lt $environmentNames.Count; $index++) {
        [Environment]::SetEnvironmentVariable($environmentNames[$index], $fixtureValues[$index], 'Process')
    }
    foreach ($environment in @('dev', 'test', 'prod')) {
        $parameterPath = Join-Path $root "infra/bicep/environments/$environment.bicepparam"
        $parameterOutput = & az bicep build-params --file $parameterPath --stdout --only-show-errors
        if ($LASTEXITCODE -ne 0) { throw "Parameter compilation failed: $environment" }
        $parameterResult = ($parameterOutput -join "`n") | ConvertFrom-Json -AsHashtable
        $parameters = $parameterResult.parametersJson | ConvertFrom-Json -AsHashtable
        Assert-True (-not $parameters.parameters.assignWorkloadReaderRoles.value) "$environment role grants disabled"
        Assert-True ($parameters.parameters.tags.value.environment -eq $environment) "$environment environment tag"
    }
} finally {
    foreach ($name in $environmentNames) { [Environment]::SetEnvironmentVariable($name, $savedValues[$name], 'Process') }
}
Write-Output "PASS: $checks infrastructure checks; compilation only, no Azure calls."