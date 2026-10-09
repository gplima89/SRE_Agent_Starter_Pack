#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$validator = Join-Path $root 'scripts/powershell/Test-Configuration.ps1'
$baseline = Get-Content (Join-Path $root 'config/dev.json') -Raw
$tempPath = Join-Path ([IO.Path]::GetTempPath()) "sre-config-$([guid]::NewGuid()).json"
$passed = 0
function Assert-Rejected {
    param([string]$Name, [scriptblock]$Mutation)
    $candidate = $baseline | ConvertFrom-Json
    & $Mutation $candidate
    $candidate | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tempPath
    $rejected = $false
    try { & $validator -ConfigPath $tempPath | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw "FAIL: $Name was accepted." }
    Write-Output "PASS: $Name rejected"
    $script:passed++
}
try {
    foreach ($environment in @('dev', 'test', 'prod')) {
        $result = & $validator -ConfigPath (Join-Path $root "config/$environment.json")
        if ($result.Status -ne 'PASS') { throw 'Baseline failed.' }
        $passed++
    }
    Assert-Rejected 'autonomy' { param($config) $config.runMode = 'Autonomous' }
    Assert-Rejected 'stage 3' { param($config) $config.agentOperatingStage = 3 }
    Assert-Rejected 'enabled automations' { param($config) $config.automationsEnabled = $true }
    Assert-Rejected 'write action' { param($config) $config.allowedActions = @('delete') }
    Assert-Rejected 'subscription-wide scope' { param($config) $config.allowedAzureScopes = @('/subscriptions/11111111-1111-1111-1111-111111111111') }
    Assert-Rejected 'cross-subscription scope' { param($config) $config.subscriptionId = '22222222-2222-2222-2222-222222222222'; $config.allowedAzureScopes = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/workload') }
    Assert-Rejected 'agent and workload same scope' { param($config) $config.subscriptionId = '11111111-1111-1111-1111-111111111111'; $config.allowedAzureScopes = @('/subscriptions/11111111-1111-1111-1111-111111111111/resourceGroups/rg-fabrikam-catalog-sre-dev') }
    Assert-Rejected 'wrong tag' { param($config) $config.tags.environment = 'prod' }
    Assert-Rejected 'invalid subscription' { param($config) $config.subscriptionId = 'not-a-guid' }
    Assert-Rejected 'unknown property' { param($config) $config | Add-Member -NotePropertyName clientSecret -NotePropertyValue 'test-only' }
    foreach ($name in @('a', '-ab', 'ab-', '1ab', ('a' * 33))) {
        $mutation = { param($config) $config.agentName = $name }.GetNewClosure()
        Assert-Rejected "invalid name $name" $mutation
    }
    foreach ($name in @('ab', ('a' * 32))) {
        $candidate = $baseline | ConvertFrom-Json
        $candidate.agentName = $name
        $candidate | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tempPath
        & $validator -ConfigPath $tempPath | Out-Null
        $passed++
    }
    $failed = $false
    try { & $validator -ConfigPath (Join-Path $root 'config/dev.json') -RequireDeploymentInputs | Out-Null } catch { $failed = $true }
    if (-not $failed) { throw 'Empty deployment inputs were accepted.' }
    $passed++
    Write-Output "PASS: $passed checks; no Azure calls or destructive tests."
} finally {
    if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath }
}