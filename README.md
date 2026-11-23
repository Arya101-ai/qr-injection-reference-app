# QR Injection Reference app (iOS)

A minimal native iOS app for checking LambdaTest camera image injection with QR codes.
It scans with `AVCaptureMetadataOutput` and matches the selectors in
`../qr-injection-test/test/specs/qr-injection.e2e.ts`, so that test runs against it unchanged.

| Element | Accessibility ID | Type | Behaviour |
|---|---|---|---|
| Scan button | `QRButton` | Button | Asks for camera permission, then opens the full-screen scanner |
| Result | `enterText` | TextView | `Waiting for scan`, then `QR Code detected: <payload>` |
| Scanner preview | `scannerView` | Other | Camera preview (black, or the injected image) |
| Close | `closeScanner` | Button | Closes the scanner without a result |

When a QR code is read, the scanner closes and the result text updates. If the camera can't start, the result shows `Scanner error: ...`.

## Build the .ipa on GitHub (no Mac needed)

1. Create a new GitHub repository and push the **contents of this folder** to it, so `.github/` is at the repo root.
2. *(Optional, recommended)* In **Settings → Secrets and variables → Actions**, add `LT_USERNAME` and `LT_ACCESS_KEY` as secrets. The workflow then uploads the .ipa to LambdaTest and shows the `lt://APP...` id in the run summary.
3. Go to **Actions → Build QR reference IPA → Run workflow**. Every push to `main` also starts a build.
4. Download the `QRInjectionRef-ipa` artifact. If you skipped step 2, upload the .ipa to LambdaTest yourself.

### Unsigned vs signed

With no signing secrets, the workflow builds an **unsigned** .ipa. Try that first, because LambdaTest re-signs the apps you upload. If LambdaTest rejects it or it won't install, add signing from an Apple Developer account:

| Secret | Value |
|---|---|
| `IOS_P12_BASE64` | `base64` of an Apple Development (or Apple Distribution) certificate `.p12` |
| `IOS_P12_PASSWORD` | Password of that `.p12` |
| `IOS_PROFILE_BASE64` | `base64` of a matching development or ad-hoc `.mobileprovision` |

Also add a repository **variable** `BUNDLE_ID` set to the App ID in that profile. Then run the workflow with `export_method` set to `development` or `ad-hoc` to match the profile. Don't use Enterprise signing: image injection doesn't support it.

## Run the QR test against it

```bash
cd ../qr-injection-test
LT_APP_URL=lt://APP<new id> LT_MEDIA_URL=lt://MEDIA<id from npm run upload> npm test
```

If LambdaTest has a per-app Image Injection setting, turn it on for this app. The test already sends `enableImageInjection: true`.
