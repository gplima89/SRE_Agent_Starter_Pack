#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param([switch]$Check)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$source = Join-Path $root 'infra/portal/main.bicep'
$destination = Join-Path $root 'infra/portal/azuredeploy.json'
$output = & az bicep build --file $source --stdout --only-show-errors
if ($LASTEXITCODE -ne 0) { throw 'Portal Bicep compilation failed; existing artifact was not changed.' }
$compiled = ($output -join "`n") | ConvertFrom-Json -AsHashtable
$compiledJson = $compiled | ConvertTo-Json -Depth 100
if ($Check) {
    if (-not (Test-Path -LiteralPath $destination)) { throw 'Portal ARM artifact is missing. Run Build-PortalTemplate.ps1.' }
    $current = Get-Content -LiteralPath $destination -Raw | ConvertFrom-Json -AsHashtable
    $currentJson = $current | ConvertTo-Json -Depth 100
    if ($currentJson -cne $compiledJson) {
        throw 'Portal ARM artifact differs from Bicep compilation. Use the pinned Bicep version and regenerate it.'
    }
    Write-Output 'PASS: Portal ARM artifact matches Bicep compilation; no Azure operations.'
} elseif ($PSCmdlet.ShouldProcess($destination, 'Regenerate compiled Portal ARM template')) {
    $temporary = "$destination.$([guid]::NewGuid()).tmp"
    try {
        [IO.File]::WriteAllText($temporary, "$compiledJson`n")
        [IO.File]::Move($temporary, $destination, $true)
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
    Write-Output 'GENERATED: Portal ARM artifact; no Azure operations.'
}