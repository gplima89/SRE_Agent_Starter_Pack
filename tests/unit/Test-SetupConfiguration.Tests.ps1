#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$generator = Join-Path $root 'scripts/powershell/New-SetupConfiguration.ps1'
$temporary = Join-Path ([IO.Path]::GetTempPath()) "sre-setup-tests-$([guid]::NewGuid())"
[IO.Directory]::CreateDirectory($temporary) | Out-Null
$inputPath = Join-Path $temporary 'setup.json'
$baseline = @{
    setupVersion = '1.0'; environment = 'dev'; organizationName = 'contoso'; workloadName = 'orders'
    tenantId = '11111111-1111-1111-1111-111111111111'; subscriptionId = '22222222-2222-2222-2222-222222222222'
    deploymentRegion = 'eastus2'; resourceGroup = 'rg-contoso-agent'; agentName = 'contoso-orders-sre'
    applicationInsightsResourceGroupName = 'rg-observability'; applicationInsightsName = 'appi-agent'
    modelProvider = 'synthetic-provider'; modelName = 'synthetic-model'; workloadResourceGroupName = ''
    assignWorkloadReaderRoles = $false; costCenter = 'CC-1234'; businessOwner = 'commerce'; technicalOwner = 'platform'
    dataClassification = 'internal'
}
$script:checks = 0
function Assert-True {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:checks++
    Write-Output "PASS: $Name"
}
function Write-Input {
    param([hashtable]$Candidate)
    [IO.File]::WriteAllText($inputPath, ($Candidate | ConvertTo-Json -Depth 10))
}
try {
    foreach ($environment in @('dev', 'test', 'prod')) {
        $candidate = $baseline.Clone()
        $candidate.environment = $environment
        $candidate.createAgentResourceGroup = $environment -eq 'prod'
        if ($environment -eq 'test') { $candidate.workloadResourceGroupName = 'rg-workload'; $candidate.assignWorkloadReaderRoles = $true }
        Write-Input $candidate
        $outputFolder = Join-Path $temporary $environment
        & $generator -SetupPath $inputPath -OutputDirectory $outputFolder | Out-Null
        $config = Get-Content (Join-Path $outputFolder "$environment.json") -Raw | ConvertFrom-Json
        $parameters = Get-Content (Join-Path $outputFolder "$environment.parameters.json") -Raw | ConvertFrom-Json
        $target = Get-Content (Join-Path $outputFolder 'deployment-target.json') -Raw | ConvertFrom-Json
        Assert-True ($config.environment -eq $environment -and $config.tags.environment -eq $environment) "$environment labels agree"
        Assert-True ($target.subscriptionId -eq $config.subscriptionId -and $target.tenantId -eq $config.tenantId) "$environment explicit target preserved"
        Assert-True ($config.createAgentResourceGroup -eq $candidate.createAgentResourceGroup -and $target.createAgentResourceGroup -eq $candidate.createAgentResourceGroup) "$environment group choice preserved"
        if ($candidate.createAgentResourceGroup) {
            Assert-True ($target.deploymentScope -eq 'subscription' -and $parameters.parameters.agentResourceGroupName.value -eq $config.resourceGroup) 'new group selects subscription template'
        } else {
            Assert-True ($target.deploymentScope -eq 'resourceGroup' -and -not ($parameters.parameters.PSObject.Properties.Name -contains 'agentResourceGroupName')) 'existing group keeps original template'
        }
        Assert-True ($parameters.parameters.agentName.value -eq $config.agentName -and $parameters.parameters.location.value -eq $config.deploymentRegion) "$environment parameter mapping"
        Assert-True ($config.runMode -eq 'Review' -and -not $config.automationsEnabled -and $config.allowedActions.Count -eq 0) "$environment safety defaults"
        & az bicep build-params --file (Join-Path $outputFolder "$environment.bicepparam") --stdout --only-show-errors | Out-Null
        Assert-True ($LASTEXITCODE -eq 0) "$environment generated Bicep compiles"
        $rejected = $false
        try { & $generator -SetupPath $inputPath -OutputDirectory $outputFolder | Out-Null } catch { $rejected = $true }
        Assert-True $rejected "$environment overwrite refused"
    }
    foreach ($case in @('missing subscription', 'invalid tenant', 'zero GUID', 'same group', 'reader without scope', 'unknown property', 'empty model', 'whitespace owner', 'invalid environment', 'empty group', 'invalid creation flag', 'monitoring in new group')) {
        $candidate = $baseline.Clone()
        switch ($case) {
            'missing subscription' { $candidate.Remove('subscriptionId') }
            'invalid tenant' { $candidate.tenantId = 'wrong' }
            'zero GUID' { $candidate.subscriptionId = '00000000-0000-0000-0000-000000000000' }
            'same group' { $candidate.workloadResourceGroupName = $candidate.resourceGroup }
            'reader without scope' { $candidate.assignWorkloadReaderRoles = $true }
            'unknown property' { $candidate.clientSecret = 'synthetic' }
            'empty model' { $candidate.modelName = '' }
            'whitespace owner' { $candidate.businessOwner = ' ' }
            'invalid environment' { $candidate.environment = '../escape' }
            'empty group' { $candidate.createAgentResourceGroup = $true; $candidate.resourceGroup = '' }
            'invalid creation flag' { $candidate.createAgentResourceGroup = 'true' }
            'monitoring in new group' { $candidate.createAgentResourceGroup = $true; $candidate.applicationInsightsResourceGroupName = $candidate.resourceGroup }
        }
        Write-Input $candidate
        $rejected = $false
        $outputFolder = Join-Path $temporary 'rejected'
        try { & $generator -SetupPath $inputPath -OutputDirectory $outputFolder | Out-Null } catch { $rejected = $true }
        Assert-True ($rejected -and -not (Test-Path $outputFolder)) "$case rejected before writing"
    }
    Write-Input $baseline
    $outputFolder = Join-Path $temporary 'preview'
    & $generator -SetupPath $inputPath -OutputDirectory $outputFolder -WhatIf | Out-Null
    Assert-True (-not (Test-Path $outputFolder)) 'WhatIf does not create output'
    $candidate = $baseline.Clone()
    $candidate.modelName = "literal'`$" + '{notCode}'
    Write-Input $candidate
    $outputFolder = Join-Path $temporary 'literal'
    & $generator -SetupPath $inputPath -OutputDirectory $outputFolder | Out-Null
    $parameters = Get-Content (Join-Path $outputFolder 'dev.parameters.json') -Raw | ConvertFrom-Json
    Assert-True ($parameters.parameters.modelName.value -ceq $candidate.modelName) 'special characters preserved as data'
    & az bicep build-params --file (Join-Path $outputFolder 'dev.bicepparam') --stdout --only-show-errors | Out-Null
    Assert-True ($LASTEXITCODE -eq 0) 'special characters cannot inject Bicep expressions'
    $compiled = & az bicep build --file (Join-Path $root 'infra/bicep/subscription.bicep') --stdout --only-show-errors
    Assert-True ($LASTEXITCODE -eq 0) 'subscription wrapper compiles'
    $template = ($compiled -join "`n") | ConvertFrom-Json -AsHashtable
    $resources = if ($template.resources -is [System.Collections.IDictionary]) { @($template.resources.Values) } else { @($template.resources) }
    $groups = @($resources | Where-Object type -EQ 'Microsoft.Resources/resourceGroups')
    $foundation = @($resources | Where-Object type -EQ 'Microsoft.Resources/deployments')[0]
    Assert-True ($template.'$schema' -match 'subscriptionDeploymentTemplate' -and $groups.Count -eq 1) 'one group at subscription scope'
    Assert-True ($groups[0].apiVersion -eq '2025-04-01' -and $groups[0].location -match 'location') 'documented group API and location'
    Assert-True ($foundation.resourceGroup -match 'agentResourceGroupName' -and $foundation.dependsOn.Count -eq 1) 'foundation waits for group creation'
    Assert-True (@($resources | Where-Object type -EQ 'Microsoft.Authorization/roleAssignments').Count -eq 0) 'no subscription role grants'
    Write-Output "PASS: $script:checks setup checks; synthetic inputs only, no cloud operations."
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force
}