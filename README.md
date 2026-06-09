# CoachPro

App Flutter per monitorare allenamenti di atletica con cronometro intelligente e squadre condivise tra coach.

## Firebase

| Risorsa | Valore |
|---------|--------|
| Progetto | `coachpro-atletica` |
| Console | https://console.firebase.google.com/project/coachpro-atletica/overview |
| Regione Firestore | `eur3` (Europa) |
| Auth | Email/Password + Google |
| Package Android | `com.coachpro.coachpro` |

### Google Sign-In su Android

Per far funzionare l'accesso con Google su dispositivo/emulatore, aggiungi la **SHA-1 debug** in Firebase Console → Impostazioni progetto → App Android:

```bash
cd android && ./gradlew signingReport
```

Copia la `SHA-1` della variante `debug` e aggiungila nella console Firebase.

Per la build **release** firmata, aggiungi anche la SHA-1 del keystore release (dopo averlo generato).

## Icona app

L'icona è generata dal logo in `assets/images/logo.png` con sfondo blu CoachPro (`#1A56B0`).

Per rigenerarla dopo modifiche al logo:

```bash
dart run flutter_launcher_icons
```

## Firma APK release (locale)

Genera keystore e `android/key.properties` (entrambi gitignored):

```powershell
.\scripts\generate_keystore.ps1
```

Poi compila:

```bash
flutter build apk --release
```

Le credenziali vengono salvate solo in `android/key.properties` sulla tua macchina. Conservale in un posto sicuro per configurare i secrets GitHub.

## CI/CD (GitHub Actions)

### CI — ogni push/PR su `main`

Workflow [`.github/workflows/ci.yml`](.github/workflows/ci.yml):

1. `flutter analyze`
2. `flutter test`
3. Build APK release di smoke test (firma debug se mancano i secrets)
4. Upload artifact APK (conservato 7 giorni)

### Release — tag `v*`

Workflow [`.github/workflows/release.yml`](.github/workflows/release.yml):

1. Quality gate (analyze + test)
2. Build **APK** e **AAB** firmati (richiede secrets di firma)
3. Upload artifact (30 giorni)
4. GitHub Release con APK + AAB allegati

#### Creare una release

```bash
# Aggiorna version in pubspec.yaml, poi:
git tag v1.0.0
git push origin v1.0.0
```

File generati:

| File | Uso |
|------|-----|
| `coachpro-v1.0.0.apk` | Installazione diretta |
| `coachpro-v1.0.0.aab` | Google Play Console |

Tag pre-release (es. `v1.0.0-beta.1`) → GitHub Release marcata come **pre-release**.

#### Release manuale (senza push tag)

**Actions → Release → Run workflow** con tag (es. `v1.0.0`).  
Deseleziona *Publish release* per fare solo build e artifact, senza pubblicare su GitHub Releases.

### Secrets obbligatori per la release

| Secret | Descrizione |
|--------|-------------|
| `ANDROID_KEYSTORE_BASE64` | Keystore codificato in base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Password keystore |
| `ANDROID_KEY_ALIAS` | Alias chiave (`upload`) |
| `ANDROID_KEY_PASSWORD` | Password chiave |

`google-services.json` è già nel repository — non serve un secret dedicato.

### Codificare il keystore per GitHub

PowerShell (Windows):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))
```

Linux/macOS:

```bash
base64 -w 0 android/app/upload-keystore.jks
```
