#Requires -Version 7.0
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$checker = Join-Path $root 'scripts/powershell/Test-Repository.ps1'
$fixture = Join-Path ([IO.Path]::GetTempPath()) "sre-repo-$([guid]::NewGuid())"
[void](New-Item -ItemType Directory -Path $fixture)
$path = Join-Path $fixture 'example.md'
try {
    $content = @'
# Example
`^[A-Za-z]([-A-Za-z0-9]{0,30}[A-Za-z0-9])$`
```text
[not-a-link](missing.md)
```
'@
    Set-Content -LiteralPath $path -Value $content
    & $checker -RepositoryRoot $fixture | Out-Null
    Write-Output 'PASS: inline and fenced code are not links'
    Set-Content -LiteralPath $path -Value '[real-link](missing.md)'
    $rejected = $false
    try { & $checker -RepositoryRoot $fixture | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Broken link accepted.' }
    Write-Output 'PASS: genuine missing link rejected'
    $credential = 'ghp_' + ('A' * 36)
    Set-Content -LiteralPath $path -Value ('```text' + "`n" + $credential + "`n" + '```')
    $rejected = $false
    try { & $checker -RepositoryRoot $fixture | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Credential in fenced code accepted.' }
    Write-Output 'PASS: credential scanning includes fenced code'
    Remove-Item -LiteralPath $path
    $nestedRoot = Join-Path $fixture 'local/repository'
    [void](New-Item -ItemType Directory -Path $nestedRoot -Force)
    Set-Content -LiteralPath (Join-Path $nestedRoot 'README.md') -Value '[real-link](missing.md)'
    $rejected = $false
    try { & $checker -RepositoryRoot $nestedRoot | Out-Null } catch { $rejected = $true }
    if (-not $rejected) { throw 'Repository under a local parent was excluded.' }
    Write-Output 'PASS: parent directory names do not exclude repository files'
    [void](New-Item -ItemType Directory -Path (Join-Path $nestedRoot 'config/local') -Force)
    Set-Content -LiteralPath (Join-Path $nestedRoot 'config/local/ignored.md') -Value '[private-fixture](missing.md)'
    Set-Content -LiteralPath (Join-Path $nestedRoot 'README.md') -Value '# Valid root'
    $result = & $checker -RepositoryRoot $nestedRoot
    if ($result.FilesChecked -ne 1) { throw 'Local configuration exclusion is not repository-relative.' }
    Write-Output 'PASS: only repository-local configuration is excluded'
} finally {
    Remove-Item -LiteralPath $fixture -Recurse -Force
}