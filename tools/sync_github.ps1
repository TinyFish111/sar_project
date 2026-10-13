[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$Message,
    [Parameter(Mandatory=$true)][string]$Paths
)
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
function Invoke-GitChecked {
    param([string[]]$Arguments)
    $output = & git -c core.quotepath=false -C $repoRoot @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments -join ' ')" }
    return $output
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is not installed.' }
$top = Invoke-GitChecked -Arguments @('rev-parse','--show-toplevel')
if ([IO.Path]::GetFullPath($top).TrimEnd('\','/') -ne $repoRoot.TrimEnd('\','/')) {
    throw 'The project must be its own Git repository.'
}
$remote = Invoke-GitChecked -Arguments @('remote','get-url','origin')
if (-not $remote) { throw 'Configure origin before syncing.' }
$branch = Invoke-GitChecked -Arguments @('symbolic-ref','--quiet','--short','HEAD')
$name = Invoke-GitChecked -Arguments @('config','user.name')
$email = Invoke-GitChecked -Arguments @('config','user.email')
if (-not $name -or -not $email) { throw 'Configure Git user.name and user.email first.' }
$staged = @(Invoke-GitChecked -Arguments @('diff','--cached','--name-only'))
if ($staged.Count -gt 0) { throw 'Existing staged changes found. Review them separately before syncing.' }

# Ignoring a file does not remove files already tracked in an older repository.
$trackedData = @(Invoke-GitChecked -Arguments @('ls-files','--','data','results','scratch','*.mat','*.fig','.env','.env.*','*.pem','*.key'))
if ($trackedData.Count -gt 0) { throw 'Previously tracked datasets/artifacts or credential files found. Review the repository before any push.' }

$allowedRoots = @('echo_generation','signal_processing','common','experiments','docs','tools')
$allowedFiles = @('AGENTS.md','README.md','.gitignore')
$selected = @($Paths.Split(',') | ForEach-Object { $_.Trim().Replace('\','/') } | Where-Object { $_ })
if ($selected.Count -eq 0) { throw 'Specify the task files using a comma-separated -Paths string.' }
foreach ($path in $selected) {
    if ([IO.Path]::IsPathRooted($path) -or $path.StartsWith('-') -or $path -match '(^|/)\.\.(/|$)' -or $path -match '[*?\[\]:]') {
        throw "Use explicit project-relative paths: $path"
    }
    $first = ($path -split '/')[0]
    if ($path -notin $allowedFiles -and $first -notin $allowedRoots) { throw "Path is outside the code/document allowlist: $path" }
}
try {
    $null = Invoke-GitChecked -Arguments (@('--literal-pathspecs','add','--') + $selected)
    $newStaged = @(Invoke-GitChecked -Arguments @('diff','--cached','--name-only','--diff-filter=ACMR'))
    foreach ($path in $newStaged) {
        $first = ($path -split '/')[0]
        if ($path -notin $allowedFiles -and $first -notin $allowedRoots) { throw "Unexpected staged file: $path" }
        if ($path -match '(?i)(\.mat|\.fig|\.pem|\.key)$|(^|/)\.env($|\.)') { throw "Data or credential file cannot be synced: $path" }
        $size = Invoke-GitChecked -Arguments @('cat-file','-s',":$path")
        if ([long]$size -gt 5MB) { throw "File exceeds the code/document size limit of 5 MiB: $path" }
    }
    $allStaged = @(Invoke-GitChecked -Arguments @('diff','--cached','--name-only'))
    if ($allStaged.Count -gt 0) {
        Invoke-GitChecked -Arguments @('diff','--cached','--stat') | Out-Host
        Invoke-GitChecked -Arguments @('commit','-m',$Message) | Out-Host
    } else {
        Write-Host 'No selected changes to commit; retrying push of the current branch.'
    }
} catch {
    Write-Warning 'Sync stopped. Local files are preserved; newly staged files may remain staged for review.'
    throw
}
$commit = Invoke-GitChecked -Arguments @('rev-parse','--short','HEAD')
Write-Host "Local commit: $commit. Pushing current branch: $branch"
Invoke-GitChecked -Arguments @('push','-u','origin',$branch) | Out-Host
Write-Host "GitHub sync succeeded. Commit: $commit"
