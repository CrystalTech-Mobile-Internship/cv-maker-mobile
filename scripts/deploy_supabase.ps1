<#
.SYNOPSIS
  Applies migrations, uploads function secrets and deploys Edge Functions to
  one Supabase project. Run once per project (primary and secondary).

.EXAMPLE
  ./scripts/deploy_supabase.ps1 -ProjectRef abcdefghijklmnop
#>
param(
  [Parameter(Mandatory = $true)][string]$ProjectRef,
  [switch]$SkipMigrations
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$secrets = Join-Path $root 'supabase/functions/.env'
if (-not (Test-Path $secrets)) {
  throw 'Missing supabase/functions/.env. Copy supabase/functions/.env.example and fill in the secrets.'
}

npx -y supabase link --project-ref $ProjectRef
if (-not $SkipMigrations) {
  npx -y supabase db push
}
npx -y supabase secrets set --env-file $secrets
Get-ChildItem (Join-Path $root 'supabase/functions') -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName 'index.ts') } |
  ForEach-Object { npx -y supabase functions deploy $_.Name --project-ref $ProjectRef }

Write-Host "Deployed to $ProjectRef" -ForegroundColor Green
