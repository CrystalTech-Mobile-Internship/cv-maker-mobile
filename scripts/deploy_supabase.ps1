<#
.SYNOPSIS
  Deploys the database changes and Edge Functions to one Supabase project.

.DESCRIPTION
  1. Resolves the project ref (parameter, or the URL of -Target in .env).
  2. Applies the listed migrations through the Supabase Management API using
     the CLI login token (no database password needed). Every migration is
     idempotent, so re-running is safe.
  3. Uploads supabase/functions/.env as function secrets.
  4. Deploys cv-assistant (and mirror-sync with -WithMirror).
  5. Verifies that cv-assistant rejects anonymous calls with HTTP 401.

  Run `npx supabase login` once before using this script.

.EXAMPLE
  ./scripts/deploy_supabase.ps1 -Target secondary
.EXAMPLE
  ./scripts/deploy_supabase.ps1 -ProjectRef abcdefghijklmnop -SkipMigrations
#>
param(
  [string]$ProjectRef,
  [ValidateSet('primary', 'secondary')][string]$Target = 'secondary',
  [switch]$SkipMigrations,
  [switch]$WithMirror,
  [string[]]$Migrations = @(
    '20261112000100_cv_layout_settings_and_template_catalog.sql',
    '20261112000200_ai_credits_and_entitlements.sql',
    '20261112000300_dual_project_mirror.sql',
    '20261112000400_community.sql',
    '20261112000500_pro_upgrade_requests.sql',
    '20261113000100_community_realtime.sql',
    '20261113000200_device_sessions.sql',
    '20261113000300_restore_updated_at_triggers.sql'
  )
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

function Read-EnvValue([string]$path, [string]$name) {
  if (-not (Test-Path $path)) { return $null }
  foreach ($line in Get-Content $path) {
    if ($line -match "^\s*$name\s*=\s*(.+)\s*$") { return $Matches[1].Trim() }
  }
  return $null
}

if (-not $ProjectRef) {
  $url = Read-EnvValue (Join-Path $root '.env') ("SUPABASE_{0}_URL" -f $Target.ToUpper())
  if (-not $url -or $url -notmatch 'https://([a-z0-9]+)\.supabase\.co') {
    throw "Cannot find SUPABASE_$($Target.ToUpper())_URL in .env. Pass -ProjectRef."
  }
  $ProjectRef = $Matches[1]
}
Write-Host "Project: $ProjectRef ($Target)"

$secrets = Join-Path $root 'supabase/functions/.env'
if (-not (Test-Path $secrets)) {
  throw 'Missing supabase/functions/.env. Copy supabase/functions/.env.example and fill in the secrets.'
}

if (-not $SkipMigrations) {
  $token = $env:SUPABASE_ACCESS_TOKEN
  if (-not $token) {
    $tokenFile = Join-Path $HOME '.supabase/access-token'
    if (Test-Path $tokenFile) { $token = (Get-Content $tokenFile -Raw).Trim() }
  }
  if (-not $token) { throw 'Not logged in. Run: npx supabase login' }

  $headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
  foreach ($name in $Migrations) {
    $file = Join-Path $root "supabase/migrations/$name"
    $sql = Get-Content $file -Raw -Encoding UTF8
    $body = @{ query = $sql } | ConvertTo-Json -Compress
    Write-Host "Applying $name ..."
    Invoke-RestMethod -Method Post -Headers $headers `
      -Uri "https://api.supabase.com/v1/projects/$ProjectRef/database/query" `
      -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) | Out-Null
  }
}

npx -y supabase secrets set --env-file $secrets --project-ref $ProjectRef
npx -y supabase functions deploy cv-assistant --project-ref $ProjectRef
if ($WithMirror) {
  npx -y supabase functions deploy mirror-sync --project-ref $ProjectRef --no-verify-jwt
}

$status = try {
  (Invoke-WebRequest -Method Post -UseBasicParsing `
    -Uri "https://$ProjectRef.supabase.co/functions/v1/cv-assistant").StatusCode
} catch { $_.Exception.Response.StatusCode.value__ }
if ($status -eq 401) {
  Write-Host 'cv-assistant is live and rejects anonymous calls (401).' -ForegroundColor Green
} else {
  Write-Warning "Unexpected status from cv-assistant: $status"
}
