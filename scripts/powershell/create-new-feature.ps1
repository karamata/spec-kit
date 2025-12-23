#!/usr/bin/env pwsh
# Create a new feature (PowerShell version, logic matches bash script)
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)
$ErrorActionPreference = 'Stop'

# --- Argument parsing for --json and --desc (mimic bash logic) ---
$JsonMode = $false
$DescMode = $false
$ShortDesc = ""
$FeatureArgs = @()
for ($i = 0; $i -lt $Args.Count; $i++) {
    $arg = $Args[$i]
    switch ($arg) {
        '--json' { $JsonMode = $true }
        '--desc' { $DescMode = $true }
        '--help' { Write-Output "Usage: ./create-new-feature.ps1 [--json] [--desc <short_description>] <feature_description>"; exit 0 }
        '-h'    { Write-Output "Usage: ./create-new-feature.ps1 [--json] [--desc <short_description>] <feature_description>"; exit 0 }
        default {
            if ($DescMode) {
                $ShortDesc = $arg
                $DescMode = $false
            } else {
                $FeatureArgs += $arg
            }
        }
    }
}

$FeatureDescription = ($FeatureArgs -join ' ').Trim()
if ([string]::IsNullOrWhiteSpace($FeatureDescription)) {
    Write-Error "Usage: ./create-new-feature.ps1 [--json] [--desc <short_description>] <feature_description>"
    exit 1
}

# --- Find repository root (prefer .specify, fallback to .git) ---
function Find-RepoRoot {
    param([string]$StartDir)
    $dir = Resolve-Path $StartDir
    while ($dir -ne [System.IO.Path]::GetPathRoot($dir)) {
        if (Test-Path (Join-Path $dir '.specify') -PathType Container) {
            return $dir
        }
        $dir = Split-Path $dir -Parent
    }
    # Fallback to .git
    $dir = Resolve-Path $StartDir
    while ($dir -ne [System.IO.Path]::GetPathRoot($dir)) {
        if (Test-Path (Join-Path $dir '.git') -PathType Container) {
            return $dir
        }
        $dir = Split-Path $dir -Parent
    }
    return $null
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Find-RepoRoot -StartDir $ScriptDir
if (-not $RepoRoot) {
    Write-Error "Error: Could not determine repository root. Please run this script from within the repository."
    exit 1
}

# Check for git
if (Test-Path (Join-Path $RepoRoot '.git') -PathType Container) {
    $HasGit = $true
} else {
    $HasGit = $false
}

Set-Location $RepoRoot

# --- Find next feature number ---
$SpecsDir = Join-Path $RepoRoot 'specs'
if (-not (Test-Path $SpecsDir)) { New-Item -ItemType Directory -Path $SpecsDir | Out-Null }
$Highest = 0
Get-ChildItem -Path $SpecsDir -Directory | ForEach-Object {
    $dirname = $_.Name
    if ($dirname -match '^(\d+)') {
        $num = [int]$matches[1]
        if ($num -gt $Highest) { $Highest = $num }
    }
}
$Next = $Highest + 1
$FeatureNum = ('{0:000}' -f $Next)

# --- Branch name logic (matches bash) ---
function Create-BranchName {
    param([string]$desc)
    $clean = $desc.ToLower() -replace '[^a-z0-9\s]', '-' -replace '\s+', '-' -replace '-+', '-' -replace '^-', '' -replace '-$', ''
    $words = $clean -split '-' | Where-Object { $_ -and $_.Length -ge 3 -and ($_ -notmatch '^(the|a|an|and|or|but|in|on|at|to|for|of|with|by|from|up|about|into|through|during|before|after|above|below|between|among|is|are|was|were|be|been|being|have|has|had|do|does|did|will|would|could|should|may|might|must|can|shall)$') }
    $branchWords = ($words | Select-Object -First 4) -join '-'
    if ($branchWords) {
        return $branchWords
    } else {
        $fallback = ($clean -split '-' | Where-Object { $_ }) | Select-Object -First 3
        return ($fallback -join '-')
    }
    
    # If we have meaningful words, use first 3-4 of them
    if ($meaningfulWords.Count -gt 0) {
        $maxWords = if ($meaningfulWords.Count -eq 4) { 4 } else { 3 }
        $result = ($meaningfulWords | Select-Object -First $maxWords) -join '-'
        return $result
    } else {
        # Fallback to original logic if no meaningful words found
        $result = ConvertTo-CleanBranchName -Name $Description
        $fallbackWords = ($result -split '-') | Where-Object { $_ } | Select-Object -First 3
        return [string]::Join('-', $fallbackWords)
    }
}

$BranchDesc = if ($ShortDesc) { $ShortDesc } else { $FeatureDescription }
$BranchWords = Create-BranchName $BranchDesc
$BranchName = "$FeatureNum-$BranchWords"

# --- Create git branch if possible ---
if ($HasGit) {
    try {
        git checkout -b $BranchName | Out-Null
    } catch {
        Write-Warning "Failed to create git branch: $BranchName"
    }
} else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $BranchName"
}

# --- Create feature directory and spec file ---
$FeatureDir = Join-Path $SpecsDir $BranchName
if (-not (Test-Path $FeatureDir)) { New-Item -ItemType Directory -Path $FeatureDir | Out-Null }
$Template = Join-Path $RepoRoot '.specify/templates/spec-template.md'
$SpecFile = Join-Path $FeatureDir 'spec.md'
if (Test-Path $Template) {
    Copy-Item $Template $SpecFile -Force
} else {
    New-Item -ItemType File -Path $SpecFile | Out-Null
}

# --- Set environment variable for current session ---
$env:SPECIFY_FEATURE = $BranchName

# --- Output ---
if ($JsonMode) {
    $obj = [PSCustomObject]@{
        BRANCH_NAME = $BranchName
        SPEC_FILE = $SpecFile
        FEATURE_NUM = $FeatureNum
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $BranchName"
    Write-Output "SPEC_FILE: $SpecFile"
    Write-Output "FEATURE_NUM: $FeatureNum"
    Write-Output "SPECIFY_FEATURE environment variable set to: $BranchName"
}

