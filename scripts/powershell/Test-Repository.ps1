<#
.SYNOPSIS
Runs lightweight repository checks without contacting Azure.
.DESCRIPTION
Checks PowerShell syntax, local Markdown links and selected credential patterns,
excluding generated and local configuration folders. Throws on findings; this is
not a dedicated secret scanner and does not validate external links or runtime behavior.
.PARAMETER RepositoryRoot
Repository directory to scan. Defaults to the root containing this script.
#>

#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$failures = [Collections.Generic.List[string]]::new()
$files = Get-ChildItem -LiteralPath $root -File -Recurse -Force |
    Where-Object {
        $repositoryPath = [IO.Path]::GetRelativePath($root, $_.FullName)
        $repositoryPath -notmatch '(^|[\\/])(\.git|\.venv|node_modules|artifacts|exports|logs)([\\/]|$)' -and
        $repositoryPath -notmatch '^config[\\/]local[\\/]'
    }
$textFiles = @($files | Where-Object { $_.Extension -in @('.md', '.json', '.ps1', '.yml', '.yaml', '.bicep', '.sh', '.tf') })
foreach ($file in $textFiles) {
    $relative = [IO.Path]::GetRelativePath($root, $file.FullName)
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($file.Extension -eq '.ps1') {
        $parseTokens = $null
        $parseErrors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$parseTokens, [ref]$parseErrors)
        if ($parseErrors.Count -gt 0) { $failures.Add("PowerShell syntax: $relative") }
    }
    if ($file.Extension -eq '.md') {
        $markdown = [regex]::Replace($content, '(?ms)^```[^\n]*\n.*?^```[^\n]*(?:\n|$)', '')
        $markdown = [regex]::Replace($markdown, '`[^`\r\n]+`', '')
        foreach ($match in [regex]::Matches($markdown, '\[[^\]]+\]\(([^\s)]+)\)')) {
            $target = $match.Groups[1].Value
            if ($target -match '^[a-zA-Z][a-zA-Z0-9+.-]*:' -or $target.StartsWith('#')) { continue }
            $pathPart = [Uri]::UnescapeDataString(($target -split '#')[0])
            $resolved = [IO.Path]::GetFullPath((Join-Path $file.DirectoryName $pathPart))
            if (-not (Test-Path -LiteralPath $resolved)) { $failures.Add("Missing local link: $relative -> $pathPart") }
        }
    }
    $patterns = @(
        '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
        'gh[pousr]_[A-Za-z0-9]{30,}',
        'github_pat_[A-Za-z0-9_]{40,}',
        'AccountKey=[A-Za-z0-9+/]{40,}={0,2}',
        'InstrumentationKey=[0-9a-fA-F-]{36}',
        'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'
    )
    foreach ($pattern in $patterns) {
        if ($content -match $pattern) { $failures.Add("Potential credential material: $relative") }
    }
}
if ($failures.Count -gt 0) { throw ($failures -join "`n") }
[pscustomobject]@{
    Status = 'PASS'
    FilesChecked = $textFiles.Count
    Checks = 'Local Markdown paths, PowerShell syntax, limited credential patterns'
    ExternalLinks = 'NOT CHECKED'
    Azure = 'NOT CHECKED'
    Note = 'A heuristic scan is not a replacement for a dedicated secret scanner or runtime tests.'
}