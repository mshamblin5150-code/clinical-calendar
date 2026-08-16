[CmdletBinding()]
param(
    [string] $FlutterExecutable = 'flutter',
    [Parameter(Mandatory = $true)]
    [string] $ExpectedSignerSha256,
    [Parameter(Mandatory = $true)]
    [string] $OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pubspecPath = Join-Path $repositoryRoot 'packages/clinical_calendar_presentation/pubspec.yaml'
$applicationPath = Join-Path $repositoryRoot 'apps/clinical_calendar'
$apkPath = Join-Path $repositoryRoot 'apps/clinical_calendar/build/app/outputs/flutter-apk/app-release.apk'
$originalPubspec = [IO.File]::ReadAllText($pubspecPath)
$baselineBytes = 84565505
$baselineSha256 = 'bbad2c0f55725fa65e214b4524d8a7a201eec429082566a4fcef9f47d8f207b6'
$baseAssets = @(
    'assets/placement_icons/',
    'assets/variant_f_raster/'
)
$catalogAssets = @(
    @{ Path = 'assets/theme_gallery_runtime/variant-f.png'; Sha256 = 'a20ed9191ddfec95d1273ea52b02e4c20bf85d54be471b6bb6898d9c55ba6205' },
    @{ Path = 'assets/shared_brand/axion-delta-mark.png'; Sha256 = '9e5c841e8781d518fe4b8052f7febe921a3a26899cc1deb769ddf0feacfeacc7' },
    @{ Path = 'assets/graphite_raster/panel-nine-slice-v1.png'; Sha256 = '4865763bc6e0ab118ceda4f437d29595ed0d599078f9454724bb498b3fbc9a15' },
    @{ Path = 'assets/theme_gallery_runtime/graphite.png'; Sha256 = 'f351730b147dae255b4416e7221248c5a5973e11a944b07394197691d2a3e1ac' },
    @{ Path = 'assets/federation_classic_raster/panel-nine-slice-v1.png'; Sha256 = 'd88711508354961c147c5d31064c48b205f3c71c511d2ee6500b0810da107689' },
    @{ Path = 'assets/federation_classic_raster/lcars-rail-nine-slice-v2.png'; Sha256 = '7859e0b60dde47fa259c6eafe12b96b5ce59facb39487a5f2e8557c76cc10b77' },
    @{ Path = 'assets/theme_gallery_runtime/federation-classic.png'; Sha256 = '478c6e01d43af4442e0e4c6750bb3c5a2710e620489c41940bed544f703da2f1' },
    @{ Path = 'assets/federation_2399_raster/panel-nine-slice-v1.png'; Sha256 = '1a11f86edb76286e6bf35c58188b23fee0a4414c0d173c8bd28f602732ec49aa' },
    @{ Path = 'assets/federation_2399_raster/dashboard-chassis-landscape-v1.png'; Sha256 = '3fd166d137f73eb9c5f9e4136b02cabd6003bb92b484f11f72d599df93de9794' },
    @{ Path = 'assets/theme_gallery_runtime/federation-2399.png'; Sha256 = '6a5382880b3c520beb991b9ccc4142aa3e77bd5cf858e2d23db881e8fb59d549' },
    @{ Path = 'assets/coastal_light_raster/panel-nine-slice-v1.png'; Sha256 = '449bee6b6097389d0fc860069160f20def2425043c20bb1e3daf29fe3f55e22f' },
    @{ Path = 'assets/coastal_light_raster/dashboard-chassis-landscape-v1.png'; Sha256 = 'b308df3a6f1ed8049c23231d82add92e49d83ee9de8dec5ddd4717154f5cbb23' },
    @{ Path = 'assets/theme_gallery_runtime/coastal-calm.png'; Sha256 = '0d752b46814cfbdcdbb94d3d68cd1edf251b09ec876cb8b231a9fbf3964879a6' },
    @{ Path = 'assets/botanical_study_raster/panel-nine-slice-v1.png'; Sha256 = 'd8dd1c290cd87789ebc01a46d15f2a1fbb32b50c4c0c9afd9da89367b16542df' },
    @{ Path = 'assets/botanical_study_raster/dashboard-chassis-landscape-v2.png'; Sha256 = '3476c3506680218e3c23939f1a42647890fcc8001be8ae9c8a3a4b6c1c509a4e' },
    @{ Path = 'assets/theme_gallery_runtime/botanical-study.png'; Sha256 = '4f1e491b56d0fa831eb04561e52bfde401f33841716d604aeb0f1bd5c589e478' },
    @{ Path = 'assets/heritage_field_notes_fonts/OFL.txt'; Sha256 = '0b3098464626138c0e2b29b95239e9f27ffbe322c6256305852018d8a9587ede' },
    @{ Path = 'assets/heritage_field_notes_materials/field-archive-chassis.png'; Sha256 = '5b4001634b5ea68a49a2389021d1398499f6bd7cc30bc03372ba9ce841ccc83e' },
    @{ Path = 'assets/heritage_field_notes_raster/panel-nine-slice-v1.png'; Sha256 = '5bdc8587d9e35595868e5ee6e983c2cfb35d06bc110bd5cbf5885345c1f2645b' },
    @{ Path = 'assets/theme_gallery_runtime/heritage-field-notes.png'; Sha256 = 'eba288dfb592b85f076a685e4d4e2ac35b9bfc168ac3a37840d89aeeac214c11' },
    @{ Path = 'assets/heritage_field_notes_fonts/RobotoCondensed-Variable.ttf'; Sha256 = 'dace262afcee68a5276f200d8026c57221735c0118ab5fda8c2c0d3dc409a8d0' }
)

function Set-AssetSlice([int] $Count) {
    $flutterSection = [regex]::Match($originalPubspec, '(?m)^flutter:\r?$')
    if (-not $flutterSection.Success) { throw 'Presentation pubspec has no Flutter section.' }
    $flutterIndex = $flutterSection.Index
    $header = $originalPubspec.Substring(0, $flutterIndex)
    $selectedAssetPaths = @($catalogAssets[0..($Count - 1)].Path) |
        Where-Object { $_ -ne 'assets/heritage_field_notes_fonts/RobotoCondensed-Variable.ttf' }
    $lines = @($baseAssets + $selectedAssetPaths) |
        ForEach-Object { "    - $_" }
    $fonts = if ($Count -eq $catalogAssets.Count) {
        "`n  fonts:`n    - family: FieldArchiveCondensed`n      fonts:`n        - asset: assets/heritage_field_notes_fonts/RobotoCondensed-Variable.ttf`n"
    } else { "`n" }
    $content = $header + "flutter:`n  uses-material-design: true`n  assets:`n" + ($lines -join "`n") + $fonts
    [IO.File]::WriteAllText($pubspecPath, $content, [Text.UTF8Encoding]::new($false))
}

function Remove-GeneratedAssetOutputs {
    $generatedPaths = @(
        'build/app/intermediates/flutter/release',
        'build/app/intermediates/assets/release',
        'build/app/intermediates/compressed_assets/release'
    )
    $applicationRoot = [IO.Path]::GetFullPath($applicationPath) + [IO.Path]::DirectorySeparatorChar
    foreach ($relativePath in $generatedPaths) {
        $targetPath = [IO.Path]::GetFullPath((Join-Path $applicationPath $relativePath))
        if (-not $targetPath.StartsWith($applicationRoot, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clear generated output outside the application: $targetPath"
        }
        if (Test-Path -LiteralPath $targetPath) {
            Remove-Item -LiteralPath $targetPath -Recurse -Force
        }
    }
}

$steps = @()
$precedingBytes = $baselineBytes
try {
    for ($index = 0; $index -lt $catalogAssets.Count; $index++) {
        Set-AssetSlice ($index + 1)
        if ($index -gt 0) { Remove-GeneratedAssetOutputs }
        & (Join-Path $PSScriptRoot 'package_signed_apk.ps1') `
            -FlutterExecutable $FlutterExecutable `
            -ExpectedSignerSha256 $ExpectedSignerSha256
        if ($LASTEXITCODE -ne 0) { throw "Marginal release build $($index + 1) failed." }
        $artifact = Get-Item -LiteralPath $apkPath
        $sha256 = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
        $contribution = $artifact.Length - $precedingBytes
        if ($contribution -le 0) { throw "Asset $($catalogAssets[$index].Path) has a non-positive marginal contribution." }
        $steps += [ordered]@{
            step = $index + 1
            assetPath = $catalogAssets[$index].Path
            assetSha256 = $catalogAssets[$index].Sha256
            precedingReleaseBytes = $precedingBytes
            releaseBytes = $artifact.Length
            artifactSha256 = $sha256
            contributionBytes = $contribution
        }
        $precedingBytes = $artifact.Length
    }
} finally {
    [IO.File]::WriteAllText($pubspecPath, $originalPubspec, [Text.UTF8Encoding]::new($false))
    # The marginal builds intentionally stage only a slice of the production
    # assets. Clear those generated outputs after restoring pubspec.yaml so the
    # following release/profile build cannot reuse the final ledger slice.
    Remove-GeneratedAssetOutputs
}

$result = [ordered]@{
    schemaVersion = 1
    candidateCommit = $env:GITHUB_SHA
    signerSha256 = $ExpectedSignerSha256.ToLowerInvariant()
    baseline = [ordered]@{ releaseBytes = $baselineBytes; artifactSha256 = $baselineSha256 }
    orderedMarginalBuilds = $steps
    releaseGrowthBytes = $precedingBytes - $baselineBytes
    attributedGrowthBytes = $precedingBytes - $baselineBytes
    unattributedGrowthBytes = 0
}
$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) { New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null }
[IO.File]::WriteAllText(
    $OutputPath,
    ($result | ConvertTo-Json -Depth 8),
    [Text.UTF8Encoding]::new($false)
)
