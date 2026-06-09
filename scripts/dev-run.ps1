# Avvia l'app UNA volta e tieni la sessione aperta.
# Dopo la prima build: usa "r" (hot reload, ~2s) o "R" (hot restart, ~5s).
# NON chiudere il terminale tra una modifica e l'altra.

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$device = & $adb devices | Select-String "device$" | Select-Object -First 1

if (-not $device) {
    Write-Error "Nessun device ADB collegato. Collega il telefono via USB."
    exit 1
}

$id = ($device -split "\s+")[0]
Write-Host "Device: $id"
Write-Host "Prima build lenta (~1-2 min). Poi hot reload con 'r' nel terminale."
flutter run -d $id
