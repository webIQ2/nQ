# Windows repo scaffold for webIQ VyOS v5

## Run in PowerShell

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.
\create-webiq-repo-layout.ps1 -SourcePath "$HOME\Downloads" -RepoRoot "$HOME\source\webiq-network-automation" -InitializeGit
```

## Expected source files in Downloads
- webIQ_clean_hubspoke_v5\
- webIQ_v5_github_actions_runbook.md
- deploy-vyos-v5.yml
- destroy-vyos-v5.yml

## Resulting layout
- .github\workflows\deploy-vyos-v5.yml
- .github\workflows\destroy-vyos-v5.yml
- infra\webIQ_clean_hubspoke_v5\...
- docs\webIQ_v5_github_actions_runbook.md
