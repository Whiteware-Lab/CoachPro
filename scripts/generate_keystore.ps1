# Genera il keystore per la firma release Android di CoachPro.
# Esegui dalla root del progetto: .\scripts\generate_keystore.ps1

$ErrorActionPreference = "Stop"

$keystorePath = "android/app/upload-keystore.jks"
$keyAlias = "upload"

if (Test-Path $keystorePath) {
    Write-Host "Keystore già presente: $keystorePath"
    exit 0
}

$storePassword = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 16 | ForEach-Object { [char]$_ })
$keyPassword = $storePassword

Write-Host "Generazione keystore in corso..."

keytool -genkeypair -v `
    -keystore $keystorePath `
    -alias $keyAlias `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -storepass $storePassword `
    -keypass $keyPassword `
    -dname "CN=CoachPro, OU=Mobile, O=CoachPro, L=Milano, ST=MI, C=IT"

$keyProperties = @"
storePassword=$storePassword
keyPassword=$keyPassword
keyAlias=$keyAlias
storeFile=app/upload-keystore.jks
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText(
    (Join-Path $PWD "android/key.properties"),
    $keyProperties,
    $utf8NoBom
)

Write-Host ""
Write-Host "Keystore creato: $keystorePath"
Write-Host "Configurazione salvata in android/key.properties (gitignored)"
Write-Host ""
Write-Host "Per GitHub Actions, aggiungi questi secrets:"
Write-Host "  ANDROID_KEYSTORE_BASE64  -> base64 del file .jks"
Write-Host "  ANDROID_KEYSTORE_PASSWORD -> $storePassword"
Write-Host "  ANDROID_KEY_ALIAS -> $keyAlias"
Write-Host "  ANDROID_KEY_PASSWORD -> $keyPassword"
Write-Host ""
Write-Host "Comando per codificare il keystore:"
Write-Host "  [Convert]::ToBase64String([IO.File]::ReadAllBytes('$keystorePath'))"
