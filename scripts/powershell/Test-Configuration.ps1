<#
.SYNOPSIS
Validates starter configuration against its schema and cross-field safety rules.
.DESCRIPTION
Checks tag consistency and workload scope boundaries without printing configuration
values or applying Azure settings. A passing result does not establish deployment readiness.
.PARAMETER ConfigPath
Path to the starter configuration JSON file to validate.
.PARAMETER RequireDeploymentInputs
Also requires the listed deployment-intent fields, one workload scope and retention.
This remains an offline completeness check, not a live prerequisite check.
#>

#Requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [switch]$RequireDeploymentInputs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$schemaPath = Join-Path $root 'config/schema/starter.schema.json'
$content = Get-Content -LiteralPath $ConfigPath -Raw
$valid = Test-Json -Json $content -SchemaFile $schemaPath -ErrorAction SilentlyContinue
if (-not $valid) {
    throw 'Configuration failed the starter schema. Values are not printed; check field types, required fields and safety constraints.'
}
$config = $content | ConvertFrom-Json
$pairs = @{
    environment = 'environment'; workload = 'workloadName'; costCenter = 'costCenter'
    businessOwner = 'businessOwner'; technicalOwner = 'technicalOwner'
    dataClassification = 'dataClassification'
}
foreach ($tag in $pairs.Keys) {
    if ($config.tags.$tag -cne $config.($pairs[$tag])) {
        throw "Tag '$tag' does not match its configuration field."
    }
}
if ($config.allowedAzureScopes.Count -gt 0) {
    $scopeSubscription = $config.allowedAzureScopes[0].Split('/')[2]
    if ([string]::IsNullOrWhiteSpace($config.subscriptionId) -or
        $scopeSubscription -ine $config.subscriptionId) {
        throw 'The allowed workload scope must match the explicit subscriptionId.'
    }
    $workloadGroup = $config.allowedAzureScopes[0].Split('/')[4]
    if ($workloadGroup -ieq $config.resourceGroup) {
        throw 'The workload resource group must be separate from the agent resource group.'
    }
}
if ($RequireDeploymentInputs) {
    foreach ($field in @('tenantId', 'subscriptionId', 'deploymentRegion', 'githubOrganization', 'githubRepository', 'logAnalyticsWorkspace', 'applicationInsightsInstance')) {
        if ([string]::IsNullOrWhiteSpace($config.$field)) {
            throw "Required deployment input '$field' is empty."
        }
    }
    if ($config.allowedAzureScopes.Count -ne 1 -or $null -eq $config.retentionDays) {
        throw 'Deployment intent requires one workload scope and an approved retentionDays value.'
    }
}
[pscustomobject]@{
    Check = 'Starter configuration'
    Status = 'PASS'
    Environment = $config.environment
    Stage = $config.agentOperatingStage
    DeploymentReadiness = 'NOT CHECKED'
    Note = 'Offline intent validation only; no Azure settings or controls were applied.'
}