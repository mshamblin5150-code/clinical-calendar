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
$apkPath = Join-Path $repositoryRoot 'apps/clinical_calendar/build/app/outputs/flutter-apk/app-release.apk'
$originalPubspec = [IO.File]::ReadAllText($pubspecPath)
$baselineBytes = 84565505
$baselineSha256 = 'bbad2c0f55725fa65e214b4524d8a7a201eec429082566a4fcef9f47d8f207b6'
$baseAssets = @(
    'assets/placement_icons/',
    'assets/variant_f_raster/'
)
$catalogAssets = @(
    @{ Path = 'assets/shared_brand/axion-delta-mark.png'; Sha256 = '9e5c841e8781d518fe4b8052f7febe921a3a26899cc1deb769ddf0feacfeacc7' },
    @{ Path = 'assets/graphite_raster/panel-nine-slice-v1.png'; Sha256 = '4865763bc6e0ab118ceda4f437d29595ed0d599078f9454724bb498b3fbc9a15' },
    @{ Path = 'assets/federation_classic_raster/panel-nine-slice-v1.png'; Sha256 = 'd88711508354961c147c5d31064c48b205f3c71c511d2ee6500b0810da107689' },
    @{ Path = 'assets/federation_classic_raster/lcars-rail-nine-slice-v2.png'; Sha256 = '7859e0b60dde47fa259c6eafe12b96b5ce59facb39487a5f2e8557c76cc10b77' },
    @{ Path = 'assets/federation_2399_raster/panel-nine-slice-v1.png'; Sha256 = '1a11f86edb76286e6bf35c58188b23fee0a4414c0d173c8bd28f602732ec49aa' },
    @{ Path = 'assets/federation_2399_raster/dashboard-chassis-landscape-v1.png'; Sha256 = '3fd166d137f73eb9c5f9e4136b02cabd6003bb92b484f11f72d599df93de9794' },
    @{ Path = 'assets/coastal_light_raster/panel-nine-slice-v1.png'; Sha256 = '449bee6b6097389d0fc860069160f20def2425043c20bb1e3daf29fe3f55e22f' },
    @{ Path = 'assets/coastal_light_raster/dashboard-chassis-landscape-v1.png'; Sha256 = 'b308df3a6f1ed8049c23231d82add92e49d83ee9de8dec5ddd4717154f5cbb23' },
    @{ Path = 'assets/botanical_study_raster/panel-nine-slice-v1.png'; Sha256 = 'd8dd1c290cd87789ebc01a46d15f2a1fbb32b50c4c0c9afd9da89367b16542df' },
    @{ Path = 'assets/botanical_study_raster/dashboard-chassis-landscape-v2.png'; Sha256 = '3476c3506680218e3c23939f1a42647890fcc8001be8ae9c8a3a4b6c1c509a4e' },
    @{ Path = 'assets/heritage_field_notes_fonts/OFL.txt'; Sha256 = '0b3098464626138c0e2b29b95239e9f27ffbe322c6256305852018d8a9587ede' },
    @{ Path = 'assets/heritage_field_notes_materials/field-archive-chassis.png'; Sha256 = '5b4001634b5ea68a49a2389021d1398499f6bd7cc30bc03372ba9ce841ccc83e' },
    @{ Path = 'assets/heritage_field_notes_raster/panel-nine-slice-v1.png'; Sha256 = '5bdc8587d9e35595868e5ee6e983c2cfb35d06bc110bd5cbf5885345c1f2645b' },
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

$steps = @()
$precedingBytes = $baselineBytes
try {
    for ($index = 0; $index -lt $catalogAssets.Count; $index++) {
        Set-AssetSlice ($index + 1)
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
}

$result = [ordered]@{
    schemaVersion = 1
    candidateCommit = $env:GITHUB_SHA
    signerSha256 = $ExpectedSignerSha256.ToLowerInvariant()
    baseline = [ordered]@{ releaseBytes = $baselineBytes; artifactSha256 = $baselineSha256 }
    orderedMarginalBuilds = $steps
    releaseGrowthBytes = $precedingBytes - $baselineBytes
    attributedGrowthBytes = ($steps | Measure-Object -Property contributionBytes -Sum).Sum
    unattributedGrowthBytes = 0
}
$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory) { New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null }
[IO.File]::WriteAllText(
    $OutputPath,
    ($result | ConvertTo-Json -Depth 8),
    [Text.UTF8Encoding]::new($false)
)
