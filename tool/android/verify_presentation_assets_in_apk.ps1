[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $ApkPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if (-not (Test-Path -LiteralPath $ApkPath -PathType Leaf)) {
    throw "APK does not exist: $ApkPath"
}

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$packageName = 'clinical_calendar_presentation'
$packageRoot = Join-Path $repositoryRoot "packages/$packageName"
$pubspecPath = Join-Path $packageRoot 'pubspec.yaml'
$lines = Get-Content -LiteralPath $pubspecPath
$assetsStart = [Array]::IndexOf($lines, '  assets:')
if ($assetsStart -lt 0) {
    throw 'Presentation pubspec has no Flutter assets section.'
}

$declaredAssets = @()
for ($index = $assetsStart + 1; $index -lt $lines.Count; $index++) {
    $line = $lines[$index]
    if ($line -match '^    -\s+(.+?)\s*$') {
        $declaredAssets += $Matches[1].Trim('''', '"')
        continue
    }
    if (-not [string]::IsNullOrWhiteSpace($line)) { break }
}
if ($declaredAssets.Count -eq 0) {
    throw 'Presentation pubspec declares no assets.'
}

$expectedEntries = foreach ($asset in $declaredAssets) {
    $localPath = Join-Path $packageRoot $asset
    if ($asset.EndsWith('/')) {
        if (-not (Test-Path -LiteralPath $localPath -PathType Container)) {
            throw "Declared presentation asset directory does not exist: $asset"
        }
        foreach ($file in Get-ChildItem -LiteralPath $localPath -File -Recurse) {
            $relative = [IO.Path]::GetRelativePath($packageRoot, $file.FullName).Replace('\', '/')
            "assets/flutter_assets/packages/$packageName/$relative"
        }
    } else {
        if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
            throw "Declared presentation asset does not exist: $asset"
        }
        "assets/flutter_assets/packages/$packageName/$($asset.Replace('\', '/'))"
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ApkPath))
try {
    $entries = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($entry in $archive.Entries) { [void]$entries.Add($entry.FullName) }
    $missing = @($expectedEntries | Where-Object { -not $entries.Contains($_) })
    if ($missing.Count -gt 0) {
        throw "APK is missing declared presentation assets:`n$($missing -join [Environment]::NewLine)"
    }
} finally {
    $archive.Dispose()
}

Write-Host "Verified $($expectedEntries.Count) declared presentation assets in APK."
