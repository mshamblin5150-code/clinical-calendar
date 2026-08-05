Set-StrictMode -Version Latest

function Get-ClinicalCalendarReleaseFlutterArguments {
  $environmentName = [Environment]::GetEnvironmentVariable(
    'CLINICAL_CALENDAR_ENVIRONMENT'
  )
  $supabaseUrl = [Environment]::GetEnvironmentVariable(
    'CLINICAL_CALENDAR_SUPABASE_URL'
  )
  $publishableKey = [Environment]::GetEnvironmentVariable(
    'CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY'
  )

  if ($environmentName -ne 'private-release') {
    throw 'Release packaging requires CLINICAL_CALENDAR_ENVIRONMENT=private-release.'
  }
  if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or
      [string]::IsNullOrWhiteSpace($publishableKey)) {
    throw 'Release packaging requires protected Supabase URL and publishable-key configuration.'
  }

  $projectUri = $null
  if (-not [Uri]::TryCreate($supabaseUrl, [UriKind]::Absolute, [ref]$projectUri) -or
      $projectUri.Scheme -ne 'https' -or
      [string]::IsNullOrWhiteSpace($projectUri.Host) -or
      -not [string]::IsNullOrEmpty($projectUri.UserInfo)) {
    throw 'Release Supabase URL must be an absolute HTTPS URL without user information.'
  }

  $key = $publishableKey.Trim()
  $isPublishable = $key.StartsWith(
    'sb_publishable_',
    [StringComparison]::Ordinal
  )
  if (-not $isPublishable) {
    $parts = $key.Split('.')
    if ($parts.Count -ne 3) {
      throw 'Release Supabase client key must be a publishable key or legacy anon JWT.'
    }
    try {
      $payload = $parts[1].Replace('-', '+').Replace('_', '/')
      switch ($payload.Length % 4) {
        2 { $payload += '==' }
        3 { $payload += '=' }
      }
      $claims = [Text.Encoding]::UTF8.GetString(
        [Convert]::FromBase64String($payload)
      ) | ConvertFrom-Json
      if ($claims.role -ne 'anon') {
        throw 'not anon'
      }
    } catch {
      throw 'Release Supabase legacy client JWT must carry only the anon role.'
    }
  }

  return @(
    '--dart-define=CLINICAL_CALENDAR_ENVIRONMENT=private-release',
    "--dart-define=CLINICAL_CALENDAR_SUPABASE_URL=$($projectUri.AbsoluteUri.TrimEnd('/'))",
    "--dart-define=CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY=$key"
  )
}
