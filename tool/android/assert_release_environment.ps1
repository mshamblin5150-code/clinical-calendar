[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$requiredEnvironment = @(
    'ANDROID_KEYSTORE_BASE64',
    'ANDROID_KEYSTORE_PASSWORD',
    'ANDROID_KEY_ALIAS',
    'ANDROID_KEY_PASSWORD',
    'ANDROID_SIGNING_CERT_SHA256'
)

foreach ($name in $requiredEnvironment) {
    $value = [Environment]::GetEnvironmentVariable($name)
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Android private release requires $name."
    }
}

$expectedFingerprint = $env:ANDROID_SIGNING_CERT_SHA256 -replace '[^0-9A-Fa-f]', ''
if ($expectedFingerprint.Length -ne 64) {
    throw 'ANDROID_SIGNING_CERT_SHA256 must be a complete SHA-256 certificate fingerprint.'
}

try {
    $decodedLength = [Convert]::FromBase64String($env:ANDROID_KEYSTORE_BASE64).Length
} catch {
    throw 'ANDROID_KEYSTORE_BASE64 is not valid Base64.'
}

if ($decodedLength -lt 1) {
    throw 'ANDROID_KEYSTORE_BASE64 decodes to an empty keystore.'
}

Write-Host 'Android release signing configuration is present and structurally valid.'

