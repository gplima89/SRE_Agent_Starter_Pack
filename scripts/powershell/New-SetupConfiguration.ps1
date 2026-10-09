<#
.SYNOPSIS
Generates an offline configuration bundle from validated setup inputs.
.DESCRIPTION
Preserves fixed safety defaults and creates starter JSON, ARM parameters, Bicep
parameters and a deployment-target record. Validates staged files before moving
them into a new output directory. Refuses overwrite and performs no Azure operations.
WhatIf previews the destination without creating the bundle.
.PARAMETER SetupPath
Path to setup JSON conforming to the setup schema and semantic safety rules.
.PARAMETER OutputDirectory
New destination directory. Defaults to config/local/<environment> in the repository.
#>

#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$SetupPath,
    [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$content = Get-Content -LiteralPath $SetupPath -Raw
$schema = Join-Path $root 'config/schema/setup.schema.json'
if (-not (Test-Json -Json $content -SchemaFile $schema -ErrorAction SilentlyContinue)) {
    throw 'Setup input failed validation. Check required fields and formats; no files were written.'
}
$setup = $content | ConvertFrom-Json -AsHashtable
if (-not $setup.ContainsKey('createAgentResourceGroup')) { $setup.createAgentResourceGroup = $false }
foreach ($key in $setup.Keys) {
    if ($setup[$key] -is [string] -and $setup[$key] -cne $setup[$key].Trim()) {
        throw "Field '$key' must not have leading or trailing spaces."
    }
}
foreach ($key in @('tenantId', 'subscriptionId')) {
    if ([guid]$setup[$key] -eq [guid]::Empty) { throw "Field '$key' must not be an all-zero GUID." }
}
if ($setup.workloadResourceGroupName -and $setup.workloadResourceGroupName -ieq $setup.resourceGroup) {
    throw 'Use separate agent and workload resource groups.'
}
if ($setup.assignWorkloadReaderRoles -and -not $setup.workloadResourceGroupName) {
    throw 'Reader-role opt-in requires a workload resource group.'
}
if ($setup.createAgentResourceGroup -and $setup.applicationInsightsResourceGroupName -ieq $setup.resourceGroup) {
    throw 'Existing monitoring must be in a different group from the new agent group.'
}

$config = Get-Content (Join-Path $root 'config/dev.json') -Raw | ConvertFrom-Json -AsHashtable
foreach ($key in @('organizationName', 'workloadName', 'environment', 'tenantId', 'subscriptionId', 'deploymentRegion', 'resourceGroup', 'agentName', 'modelProvider', 'modelName', 'costCenter', 'businessOwner', 'technicalOwner', 'dataClassification')) {
    $config[$key] = $setup[$key]
}
$config.applicationInsightsInstance = $setup.applicationInsightsName
$config.applicationInsightsResourceGroupName = $setup.applicationInsightsResourceGroupName
$config.assignWorkloadReaderRoles = $setup.assignWorkloadReaderRoles
$config.createAgentResourceGroup = $setup.createAgentResourceGroup
$config.deploymentMode = 'bicep'
$config.agentOperatingStage = 0
$config.runMode = 'Review'
$config.automationsEnabled = $false
$config.allowedActions = @()
$config.allowedAzureScopes = @()
if ($setup.workloadResourceGroupName) {
    $config.allowedAzureScopes = @("/subscriptions/$($setup.subscriptionId)/resourceGroups/$($setup.workloadResourceGroupName)")
}
$config.tags = [ordered]@{
    environment = $setup.environment
    managedBy = 'azure-sre-agent-starter'
    workload = $setup.workloadName
    costCenter = $setup.costCenter
    businessOwner = $setup.businessOwner
    technicalOwner = $setup.technicalOwner
    dataClassification = $setup.dataClassification
}
$configJson = $config | ConvertTo-Json -Depth 20
if (-not (Test-Json -Json $configJson -SchemaFile (Join-Path $root 'config/schema/starter.schema.json') -ErrorAction SilentlyContinue)) {
    throw 'Generated starter configuration failed validation; no files were written.'
}
$parameters = [ordered]@{}
foreach ($key in @('agentName', 'workloadResourceGroupName', 'assignWorkloadReaderRoles', 'applicationInsightsResourceGroupName', 'modelProvider', 'modelName')) {
    $parameters[$key] = @{ value = $setup[$key] }
}
$parameters.location = @{ value = $setup.deploymentRegion }
$parameters.applicationInsightsName = @{ value = $setup.applicationInsightsName }
$parameters.tags = @{ value = $config.tags }
$templateName = 'main.bicep'
$deploymentScope = 'resourceGroup'
if ($setup.createAgentResourceGroup) {
    $templateName = 'subscription.bicep'
    $deploymentScope = 'subscription'
    $parameters.agentResourceGroupName = @{ value = $setup.resourceGroup }
}
$parameterJson = [ordered]@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = $parameters
} | ConvertTo-Json -Depth 20
$targetJson = [ordered]@{
    tenantId = $setup.tenantId
    subscriptionId = $setup.subscriptionId
    resourceGroup = $setup.resourceGroup
    environment = $setup.environment
    createAgentResourceGroup = $setup.createAgentResourceGroup
    deploymentScope = $deploymentScope
    deploymentLocation = $setup.deploymentRegion
    template = "infra/bicep/$templateName"
    deploymentReadiness = 'NOT CHECKED'
} | ConvertTo-Json

if (-not $OutputDirectory) { $OutputDirectory = Join-Path $root "config/local/$($setup.environment)" }
$destination = [IO.Path]::GetFullPath($OutputDirectory)
if (Test-Path -LiteralPath $destination) { throw 'Output directory already exists. Choose a new folder; existing files will not be overwritten.' }
$templatePath = [IO.Path]::GetRelativePath($destination, (Join-Path $root "infra/bicep/$templateName")).Replace('\', '/')
$templatePath = $templatePath.Replace("'", "\'").Replace('${', '\${')
$bicepLines = @("using '$templatePath'", '', "var inputs = loadJsonContent('./$($setup.environment).parameters.json')", '')
foreach ($key in $parameters.Keys) { $bicepLines += "param $key = inputs.parameters.$key.value" }
if (-not $PSCmdlet.ShouldProcess($destination, 'Create offline configuration bundle; no Azure calls')) { return }
$parent = Split-Path $destination -Parent
[IO.Directory]::CreateDirectory($parent) | Out-Null
$staging = Join-Path $parent ".sre-setup-$([guid]::NewGuid())"
try {
    [IO.Directory]::CreateDirectory($staging) | Out-Null
    [IO.File]::WriteAllText((Join-Path $staging "$($setup.environment).json"), $configJson)
    [IO.File]::WriteAllText((Join-Path $staging "$($setup.environment).parameters.json"), $parameterJson)
    [IO.File]::WriteAllText((Join-Path $staging "$($setup.environment).bicepparam"), ($bicepLines -join "`n"))
    [IO.File]::WriteAllText((Join-Path $staging 'deployment-target.json'), $targetJson)
    & (Join-Path $PSScriptRoot 'Test-Configuration.ps1') -ConfigPath (Join-Path $staging "$($setup.environment).json") | Out-Null
    [IO.Directory]::Move($staging, $destination)
} finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
}
[pscustomobject]@{
    Status = 'GENERATED'
    Directory = $destination
    Environment = $setup.environment
    DeploymentReadiness = 'NOT CHECKED'
    Note = 'No Azure calls. Deployment must explicitly use the configured subscription and resource group.'
}