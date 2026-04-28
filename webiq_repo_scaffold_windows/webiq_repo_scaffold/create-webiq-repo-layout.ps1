param(
  [string]$SourcePath = "$HOME\Downloads",
  [string]$RepoRoot = "$HOME\source\webiq-network-automation",
  [switch]$InitializeGit
)

$ErrorActionPreference = 'Stop'

function Copy-IfExists {
  param(
    [string]$From,
    [string]$To
  )
  if (Test-Path $From) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $To) -Force | Out-Null
    Copy-Item -Path $From -Destination $To -Recurse -Force
    Write-Host "Copied: $From -> $To" -ForegroundColor Green
  } else {
    Write-Warning "Missing: $From"
  }
}

Write-Host "Creating repository layout at: $RepoRoot" -ForegroundColor Cyan

$folders = @(
  "$RepoRoot\.github\workflows",
  "$RepoRoot\infra",
  "$RepoRoot\docs"
)

foreach ($folder in $folders) {
  New-Item -ItemType Directory -Path $folder -Force | Out-Null
}

Copy-IfExists -From "$SourcePath\webIQ_clean_hubspoke_v5" -To "$RepoRoot\infra\webIQ_clean_hubspoke_v5"
Copy-IfExists -From "$SourcePath\webIQ_v5_github_actions_runbook.md" -To "$RepoRoot\docs\webIQ_v5_github_actions_runbook.md"
Copy-IfExists -From "$SourcePath\deploy-vyos-v5.yml" -To "$RepoRoot\.github\workflows\deploy-vyos-v5.yml"
Copy-IfExists -From "$SourcePath\destroy-vyos-v5.yml" -To "$RepoRoot\.github\workflows\destroy-vyos-v5.yml"

$readme = @"
# webiq-network-automation

## Layout
- .github/workflows/
- infra/webIQ_clean_hubspoke_v5/
- docs/

## Next steps
1. Review workflow paths under .github/workflows.
2. Create GitHub Environments: lab and destroy.
3. Add environment secrets:
   - AZURE_CLIENT_ID
   - AZURE_TENANT_ID
   - AZURE_SUBSCRIPTION_ID
   - ADMIN_SOURCE_PREFIX
   - NVA_ADMIN_PASSWORD
   - TEST_VM_SSH_PUBLIC_KEY
4. Commit and push to GitHub.
"@

Set-Content -Path "$RepoRoot\README.md" -Value $readme -Encoding UTF8
Write-Host "Wrote: $RepoRoot\README.md" -ForegroundColor Green

if ($InitializeGit) {
  if (-not (Test-Path "$RepoRoot\.git")) {
    Push-Location $RepoRoot
    git init
    git add .
    git commit -m "Initial webIQ VyOS v5 CI/CD layout"
    Pop-Location
    Write-Host "Initialized git repository and created initial commit." -ForegroundColor Green
  } else {
    Write-Host "Git repository already exists at $RepoRoot" -ForegroundColor Yellow
  }
}

Write-Host "Done." -ForegroundColor Cyan
