param(
  [Parameter(Mandatory=$true)]
  [string]$RepoRoot,
  [string]$SourcePackageRoot = $PSScriptRoot,
  [switch]$InitializeGit
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $RepoRoot)) {
  New-Item -ItemType Directory -Path $RepoRoot | Out-Null
}

Get-ChildItem -Force $RepoRoot | Where-Object { $_.Name -ne '.git' } | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot '.github\workflows') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot 'docs') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot 'infra') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RepoRoot 'scripts') | Out-Null

Copy-Item (Join-Path $SourcePackageRoot '.github\workflows\deploy-vyos-v5.yml') (Join-Path $RepoRoot '.github\workflows\deploy-vyos-v5.yml') -Force
Copy-Item (Join-Path $SourcePackageRoot '.github\workflows\destroy-vyos-v5.yml') (Join-Path $RepoRoot '.github\workflows\destroy-vyos-v5.yml') -Force
Copy-Item (Join-Path $SourcePackageRoot 'docs\webIQ_v5_github_actions_runbook.md') (Join-Path $RepoRoot 'docs\webIQ_v5_github_actions_runbook.md') -Force
Copy-Item (Join-Path $SourcePackageRoot 'infra\webIQ_clean_hubspoke_v5') (Join-Path $RepoRoot 'infra\webIQ_clean_hubspoke_v5') -Recurse -Force
Copy-Item (Join-Path $SourcePackageRoot 'README.md') (Join-Path $RepoRoot 'README.md') -Force

if ($InitializeGit) {
  Push-Location $RepoRoot
  if (-not (Test-Path (Join-Path $RepoRoot '.git'))) {
    git init | Out-Null
  }
  git add .
  git commit -m "Restore webIQ VyOS v5 CI/CD baseline" | Out-Null
  Pop-Location
}

Write-Host "Repo layout restored at: $RepoRoot"
