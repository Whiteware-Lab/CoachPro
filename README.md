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

## Release APK (GitHub Actions)

Il workflow [`.github/workflows/release.yml`](.github/workflows/release.yml) compila l'APK release e pubblica una GitHub Release quando viene pushato un tag `v*`.

### Creare una release

```bash
git tag v1.0.0
git push origin v1.0.0
```

L'APK viene allegato alla release con nome `coachpro-v1.0.0.apk`.

I tag con suffisso pre-release (es. `v1.0.0-beta.1`) vengono marcati come **pre-release**.

### Trigger manuale

Da **Actions → Build and Release APK → Run workflow** puoi avviare una build indicando il tag (es. `v1.0.0`). Utile per testare la pipeline prima del push del tag.

### Secrets consigliati (GitHub → Settings → Secrets and variables → Actions)

| Secret | Obbligatorio | Descrizione |
|--------|--------------|-------------|
| `GOOGLE_SERVICES_JSON` | No* | Contenuto di `google-services.json` codificato in base64 |
| `ANDROID_KEYSTORE_BASE64` | No | Keystore di firma codificato in base64 |
| `ANDROID_KEYSTORE_PASSWORD` | No | Password del keystore |
| `ANDROID_KEY_ALIAS` | No | Alias della chiave |
| `ANDROID_KEY_PASSWORD` | No | Password della chiave |

\* Se `android/app/google-services.json` è committato nel repository, il secret non è necessario.

Senza keystore configurato nei secrets, la CI produce un APK firmato con la debug key (solo per test).

### Codificare i file per i secrets

PowerShell (Windows):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/google-services.json"))
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks"))
```

Linux/macOS:

```bash
base64 -w 0 android/app/google-services.json
base64 -w 0 android/app/upload-keystore.jks
```
