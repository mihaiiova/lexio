# Slove Release Signing Setup

This guide configures the GitHub Actions secrets required to build signed Android and iOS releases. Never commit certificates, provisioning profiles, keystores, passwords, or API keys.

## Android

1. In Android Studio, open **Build > Generate Signed Bundle / APK** and create an upload key for `com.mihaiiova.lexio`.
2. Store the generated `.jks` file and its passwords in a password manager or other secure backup. Losing the upload key prevents future Play updates.
3. In GitHub, open **Settings > Secrets and variables > Actions** and add these repository secrets:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Base64 encoding of the `.jks` upload key |
| `ANDROID_KEYSTORE_PASSWORD` | Upload-key store password |
| `ANDROID_KEY_ALIAS` | Upload-key alias |
| `ANDROID_KEY_PASSWORD` | Upload-key password |

On macOS, generate the first value without writing the encoded key to disk:

```sh
base64 < /secure/path/upload-keystore.jks | pbcopy
```

## iOS And TestFlight

1. In the Apple Developer portal, create an App ID for `com.mihaiiova.lexio` if it does not already exist.
2. Create an **Apple Distribution** certificate, export it as password-protected `.p12`, and create an **App Store** provisioning profile for the App ID.
3. In App Store Connect, create an API key with App Manager access or higher. Download its `.p8` file immediately; Apple makes it available only once.
4. In GitHub Actions secrets, add:

| Secret | Value |
|---|---|
| `IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Base64 encoding of the distribution `.p12` |
| `IOS_P12_PASSWORD` | Password used when exporting the `.p12` |
| `IOS_PROVISION_PROFILE_BASE64` | Base64 encoding of the App Store provisioning profile |
| `IOS_TEAM_ID` | Apple Developer Team ID |
| `KEYCHAIN_PASSWORD` | A unique random password for the temporary CI keychain |
| `APPSTORE_ISSUER_ID` | App Store Connect API issuer ID |
| `APPSTORE_KEY_ID` | App Store Connect API key ID |
| `APPSTORE_API_KEY_BASE64` | Base64 encoding of the downloaded `.p8` API key |

Use the same macOS command shown for Android to base64-encode each binary file before adding it as a secret.

## Android Play upload

Android builds are uploaded to Google Play automatically by the
`r0adkll/upload-google-play` action. This requires a Google Play service account.

1. In **Google Cloud Console**, create a project (or reuse one), enable the
   **Google Play Android Developer API**, then create a **Service Account**.
2. Create a JSON key for the service account and download it.
3. In **Google Play Console** → Users and permissions, invite the service
   account email with **Release manager** (or App access) permission.
4. In GitHub, open **Settings > Secrets and variables > Actions > Environments
   > Prod** and add:

| Secret | Value |
|---|---|
| `ANDROID_PLAY_SERVICE_ACCOUNT_JSON` | The full raw JSON contents of the service-account key |

Paste the raw JSON (including braces) as the secret value. The workflow reads it
via `serviceAccountJsonPlainText`.

## Verification

1. Push to `staging` — the **Deploy staging to test** workflow should upload a
   signed Android AAB to the Play internal-testing track and a signed IPA to
   TestFlight.
2. Push to `master` — the **Deploy to production** workflow should upload to the
   Play production track and to App Store Connect.
