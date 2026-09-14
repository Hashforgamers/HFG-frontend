# App Links / Universal Links verification

Neither domain currently serves these files, so `android:autoVerify="true"` in
`AndroidManifest.xml` fails and the `applinks:` entries in
`ios/Runner/Runner.entitlements` never activate. Links open the browser instead
of the app. **The app-side deep link code cannot work until these are live.**

Verified 2026-09-14:

    https://hashforgamers.co.in/.well-known/assetlinks.json              404
    https://hashforgamers.co.in/.well-known/apple-app-site-association   404
    https://hashforgamers.com/.well-known/assetlinks.json                404

## Where they go

Both files must be served from the web root of **every** declared host, over
HTTPS, with no redirects:

    https://hashforgamers.co.in/.well-known/assetlinks.json
    https://www.hashforgamers.co.in/.well-known/assetlinks.json
    https://hashforgamers.com/.well-known/assetlinks.json
    https://www.hashforgamers.com/.well-known/assetlinks.json

    ...and the same four paths for apple-app-site-association

These domains are not served from this repository (`firebase.json` has no
`hosting` block), so deploying them is a web-infrastructure task.

## Content type

- `assetlinks.json` → `application/json`
- `apple-app-site-association` → `application/json`, **no `.json` extension**,
  and it must not be redirected.

## Before deploying assetlinks.json

`sha256_cert_fingerprints` is a placeholder. Use the fingerprint of the
certificate that actually signs the installed app:

- **Distributed through Google Play** (the normal case): take it from
  Play Console → your app → Test and release → Setup → App signing → *App
  signing key certificate* → SHA-256. The local upload keystore in
  `android/key.properties` is the **wrong** key — using it is the most common
  reason App Links silently fail to verify.
- **Sideloaded / self-signed builds only**: derive it from the release keystore
  with `keytool -list -v -keystore <path> -alias <alias>`.

Both fingerprints may be listed together if you also distribute builds signed
with the upload key.

## Verifying after deploy

    # Android
    adb shell pm verify-app-links --re-verify com.hfg.hash
    adb shell pm get-app-links com.hfg.hash        # expect "verified"

    # Apple's CDN caches the AASA; check what it actually serves
    curl -sI https://app-site-association.cdn-apple.com/a/v1/hashforgamers.co.in

Identifiers used in these files: Android package `com.hfg.hash`; iOS app ID
`B5GC6C37H8.com.hashforgamers.app` (team `B5GC6C37H8`, bundle
`com.hashforgamers.app`).

The path lists here mirror the intent filters in `AndroidManifest.xml` and the
destinations `DeepLinkService.parse` resolves. Keep all three in step.
