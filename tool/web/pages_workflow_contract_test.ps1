$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$qualityPath = Join-Path $repositoryRoot '.github\workflows\quality.yml'
$pagesPath = Join-Path $repositoryRoot '.github\workflows\pages.yml'

function Assert-Matches {
  param(
    [Parameter(Mandatory)][string]$Content,
    [Parameter(Mandatory)][string]$Pattern,
    [Parameter(Mandatory)][string]$Message
  )
  if ($Content -notmatch $Pattern) {
    throw $Message
  }
}

$quality = Get-Content -LiteralPath $qualityPath -Raw
Assert-Matches $quality 'flutter build web --release' `
  'Quality must build the release web app.'

if (-not (Test-Path -LiteralPath $pagesPath)) {
  throw 'The GitHub Pages workflow is missing.'
}
$pages = Get-Content -LiteralPath $pagesPath -Raw

Assert-Matches $pages '(?s)workflow_run:.*workflows:\s*\[Quality\].*types:\s*\[completed\]' `
  'Pages must listen for completed Quality workflow runs.'
Assert-Matches $pages 'workflow_dispatch:' `
  'Pages must also support a manual dispatch.'
foreach ($permission in @('contents: read', 'pages: write', 'id-token: write')) {
  Assert-Matches $pages ([regex]::Escape($permission)) `
    "Pages is missing the required '$permission' permission."
}
Assert-Matches $pages '(?s)concurrency:.*group:\s*pages.*cancel-in-progress:\s*false' `
  'Pages runs must queue without cancelling an in-progress deployment.'

foreach ($gate in @(
    "github.event_name == 'workflow_dispatch'",
    "github.event.workflow_run.event == 'push'",
    "github.event.workflow_run.head_branch == 'main'",
    "github.event.workflow_run.conclusion == 'success'"
  )) {
  Assert-Matches $pages ([regex]::Escape($gate)) `
    "The build job is missing its required gate: $gate"
}
Assert-Matches $pages 'ref:\s*\$\{\{ github\.event\.workflow_run\.head_sha \|\| github\.sha \}\}' `
  'Pages must check out the commit that passed Quality.'
Assert-Matches $pages '(?s)build:.*environment:\s*github-pages' `
  'The build job must read configuration from the github-pages environment.'

foreach ($configuration in @(
    'CLINICAL_CALENDAR_ENVIRONMENT: ${{ vars.CLINICAL_CALENDAR_ENVIRONMENT }}',
    'CLINICAL_CALENDAR_SUPABASE_URL: ${{ vars.CLINICAL_CALENDAR_SUPABASE_URL }}',
    'CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY: ${{ secrets.CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY }}'
  )) {
  Assert-Matches $pages ([regex]::Escape($configuration)) `
    "Pages is missing its environment input: $configuration"
}
Assert-Matches $pages ([regex]::Escape('./tool/web/build_pages.ps1')) `
  'Pages must build through the validated web release wrapper.'
Assert-Matches $pages 'actions/upload-pages-artifact@' `
  'Pages must upload a Pages artifact.'
Assert-Matches $pages 'path:\s*apps/clinical_calendar/build/web' `
  'Pages must upload the Flutter web output.'
Assert-Matches $pages '(?s)deploy:.*needs:\s*build.*environment:.*name:\s*github-pages' `
  'Deploy must wait for build and target the github-pages environment.'
Assert-Matches $pages 'actions/deploy-pages@' `
  'Pages must deploy with the official Pages action.'

Write-Host 'Pages workflow contract passed.'
