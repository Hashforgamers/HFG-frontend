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

## Deploying on Vercel (the website host)

Checked 2026-09-28: all four hosts are Vercel. `hashforgamers.com` 307s to
`www.hashforgamers.com` (404) and `www.hashforgamers.co.in` 307s to
`hashforgamers.co.in` (404). Apple does **not** follow redirects for the AASA,
so each host must answer with the file directly.

1. Copy `apple-app-site-association` and `assetlinks.json` into the website
   repo's `public/.well-known/` (Next.js) or `.well-known/` at the static root.
2. Merge `deploy/vercel/vercel.json` into the website's `vercel.json`. It sets
   `Content-Type: application/json` and moves the apex/www canonical redirects
   into `vercel.json` with `/.well-known/` excluded.
3. In Vercel → Project → Domains, remove the dashboard-level redirects for
   `hashforgamers.com` and `www.hashforgamers.co.in` (dashboard redirects apply
   to every path, including `/.well-known/`) and attach all four domains to the
   project. The `vercel.json` redirects replace them.
4. Verify every host returns `200` + `application/json`, no redirect:

       for d in hashforgamers.com www.hashforgamers.com hashforgamers.co.in www.hashforgamers.co.in; do
         curl -sI https://$d/.well-known/apple-app-site-association | head -1
         curl -sI https://$d/.well-known/assetlinks.json | head -1
       done

   Apple caches the AASA through its CDN; check what iOS will see with
   `https://app-site-association.cdn-apple.com/a/v1/hashforgamers.com`.

`assetlinks.json` includes the local debug-keystore fingerprint so dev builds
verify. Replace `REPLACE_WITH_PLAY_APP_SIGNING_SHA256` with the SHA-256 from
Play Console → Test and release → App integrity → App signing key certificate
before relying on it for Play installs.
