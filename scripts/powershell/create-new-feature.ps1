#!/usr/bin/env pwsh
# Create a new feature
[CmdletBinding()]
param(
    [switch]$Json,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FeatureDescription
)
$ErrorActionPreference = 'Stop'

if (-not $FeatureDescription -or $FeatureDescription.Count -eq 0) {
    Write-Error "Usage: ./create-new-feature.ps1 [-Json] <feature description>"
    exit 1
}
$featureDesc = ($FeatureDescription -join ' ').Trim()

# Function to find the repository root by searching for existing project markers
# Prioritizes .specify directory over .git to handle nested git repositories
function Find-RepositoryRoot {
    param(
        [string]$StartDir
    )
    $current = Resolve-Path $StartDir
    
    # First check for .specify directory (project root marker)
    while ($current -ne [System.IO.Path]::GetPathRoot($current)) {
        if (Test-Path (Join-Path $current '.specify') -PathType Container) {
            return $current
        }
        $current = Split-Path $current -Parent
    }
    
    # If no .specify found, look for .git as fallback
    $current = Resolve-Path $StartDir
    while ($current -ne [System.IO.Path]::GetPathRoot($current)) {
        if (Test-Path (Join-Path $current '.git') -PathType Container) {
            return $current
        }
        $current = Split-Path $current -Parent
    }
    
    return $null
}

# Resolve repository root. Prefer .specify directory when available, then fall back
# to git information, and finally to searching for repository markers.
$fallbackRoot = Find-RepositoryRoot -StartDir $PSScriptRoot
if (-not $fallbackRoot) {
    Write-Error "Error: Could not determine repository root. Please run this script from within the repository."
    exit 1
}

# First try to find .specify directory (project root)
if (Test-Path (Join-Path $fallbackRoot '.git') -PathType Container) {
    $hasGit = $true
} else {
    $hasGit = $false
}

try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        # We have git, but still prefer .specify if it exists
        if (Test-Path (Join-Path $repoRoot '.specify') -PathType Container) {
            $repoRoot = $fallbackRoot
        }
    } else {
        throw "Git not available"
    }
} catch {
    $repoRoot = $fallbackRoot
    $hasGit = $false
}

Set-Location $repoRoot

$specsDir = Join-Path $repoRoot 'specs'
New-Item -ItemType Directory -Path $specsDir -Force | Out-Null

$highest = 0
if (Test-Path $specsDir) {
    Get-ChildItem -Path $specsDir -Directory | ForEach-Object {
        if ($_.Name -match '^(\d{3})') {
            $num = [int]$matches[1]
            if ($num -gt $highest) { $highest = $num }
        }
    }
}
$next = $highest + 1
$featureNum = ('{0:000}' -f $next)

$branchName = $featureDesc.ToLower() -replace '[^a-z0-9]', '-' -replace '-{2,}', '-' -replace '^-', '' -replace '-$', ''
$words = ($branchName -split '-') | Where-Object { $_ } | Select-Object -First 3
$branchName = "$featureNum-$([string]::Join('-', $words))"

if ($hasGit) {
    try {
        git checkout -b $branchName | Out-Null
    } catch {
        Write-Warning "Failed to create git branch: $branchName"
    }
} else {
    Write-Warning "[specify] Warning: Git repository not detected; skipped branch creation for $branchName"
}

$featureDir = Join-Path $specsDir $branchName
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

$template = Join-Path $repoRoot '.specify/templates/spec-template.md'
$specFile = Join-Path $featureDir 'spec.md'
if (Test-Path $template) { 
    Copy-Item $template $specFile -Force 
} else { 
    New-Item -ItemType File -Path $specFile | Out-Null 
}

# Set the SPECIFY_FEATURE environment variable for the current session
$env:SPECIFY_FEATURE = $branchName

if ($Json) {
    $obj = [PSCustomObject]@{ 
        BRANCH_NAME = $branchName
        SPEC_FILE = $specFile
        FEATURE_NUM = $featureNum
    }
    $obj | ConvertTo-Json -Compress
} else {
    Write-Output "BRANCH_NAME: $branchName"
    Write-Output "SPEC_FILE: $specFile"
    Write-Output "FEATURE_NUM: $featureNum"
    Write-Output "SPECIFY_FEATURE environment variable set to: $branchName"
}
