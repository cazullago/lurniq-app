# Google Play release checklist — Lurniq

The debug APK is for testing now. This checklist is the path to a Play Store
listing. Legend: **[x] done in-repo** · **[ ] user-side** (needs the app
owner's account, identity, or action).

## App identity & versioning

- [x] `applicationId` reserved: **`com.lurniq.app`** (`android/app/build.gradle.kts`)
- [x] Version discipline: `pubspec.yaml` `version: 2.0.0+2` → versionName `2.0.0`, versionCode `2`. Bump versionCode on **every** release; never reuse one.
- [x] App name "Lurniq" + original launcher icon (adaptive + legacy PNGs, 100% original artwork, no brand marks)

## Signing

- [x] Release `signingConfig` wired to `android/keystore.properties` **or** CI secrets (`LURNIQ_KEYSTORE_BASE64`, `LURNIQ_STORE_PASSWORD`, `LURNIQ_KEY_ALIAS`, `LURNIQ_KEY_PASSWORD`); falls back to debug signing when absent (test builds only)
- [x] `keystore.properties` + `*.keystore`/`*.jks` git-ignored
- [ ] **User-side:** create the upload keystore **once** and back it up (losing it = new app listing):
  ```bash
  keytool -genkeypair -v -keystore lurniq-upload.keystore -alias lurniq \
    -keyalg RSA -keysize 2048 -validity 10000
  ```
  Then either fill in `android/keystore.properties` (local builds) or add the four GitHub secrets (CI builds; base64 the keystore file for `LURNIQ_KEYSTORE_BASE64`).
- [ ] **User-side:** enroll in **Play App Signing** (recommended) when creating the release.

## Play Console setup (all user-side)

- [ ] **User-side:** Google Play developer account — **$25 one-time** (organization accounts need D-U-N-S verification)
- [ ] **User-side:** create the app in Play Console (package `com.lurniq.app`), complete the **content rating questionnaire** (IARC)
- [ ] **User-side:** fill in the **Data safety form** (v2):
  - Camera / photos: collected **only** when the user captures or attaches an image (lesson photos, post images, profile photo, chat images, grade photos); stored on-device, never sold
  - Notifications: **on-device only** (session reminders, enrollment/booking alerts) — no data leaves the device
  - AI study helper: if the user enters their own API key, prompts are sent to their AI provider (Google AI Studio/Gemini via the OpenAI-compatible endpoint); demo AI runs fully on-device with template responses
  - Messaging: demo-mode threads stored **on-device only**; block/report stored on-device
  - Lurniq Plus: subscription screen is "Coming soon" — **no billing, no payment data collected** in v2
  - No precise location collected (study groups use user-typed public places only)
  - No contacts, no call logs
  - Account deletion: in-app (Settings → Delete account) wipes on-device data
- [ ] **User-side:** privacy policy **URL** (host `docs/privacy-policy-template.md` after legal review — see below)
- [ ] **User-side:** store listing assets:
  - App icon 512×512 (export from `assets/icon/lurniq-icon.svg`)
  - **Feature graphic 1024×500** — guidance: warm cream background, the Lurniq book+spark mark left, the tagline "A smarter way to learn." in a clean sans-serif; no screenshots of other brands, no misleading claims
  - 2–8 phone screenshots (use the release build, light theme)
  - Short + full description, category: Education
- [ ] **User-side:** target API compliance — CI builds with the latest stable Flutter (targetSdk = `flutter.targetSdkVersion`); confirm the Play Console shows no API-level warnings before each release
- [ ] **User-side:** **12-tester closed testing requirement** — new personal Play accounts must run a closed test with ≥12 testers for 14 days before production access is granted. Plan: internal → closed (12 testers, 14 days) → production.

## Legal

- [x] In-app **Terms of Service**, **Privacy Policy**, and **Tutor Agreement** are real **drafts** (`lib/screens/legal/legal_screens.dart`) — every surface banners "Draft for review — not legal advice. Must be reviewed by a lawyer before accepting real payments."
- [x] Sign-up requires ToS + Privacy Policy acceptance (version + timestamp stored); tutor listing requires Tutor Agreement acceptance (version-gated)
- [x] `LEGAL_CHECKLIST.md`: BIR registration, Data Privacy Act/NPC, Play Data Safety mapping, lawyer-review gate before payments, Stripe Connect, tutor age verification
- [ ] **User-side:** lawyer review of all three documents (REQUIRED before enabling payments or publishing)
- [ ] **User-side:** host the reviewed Privacy Policy at a public URL and paste the URL into Play Console

## Pre-upload verification (in-repo, run every release)

- [x] `flutter analyze --no-fatal-infos` clean (CI-enforced)
- [x] `flutter test` green (CI-enforced)
- [x] Manifest/dex sanity: `aapt dump xmltree` shows `.MainActivity`; `classes.dex` contains `Lcom/lurniq/app/MainActivity;` (verified on v1.0.0)
- [x] Permissions declared (v2): camera + photos (point-of-need with rationale), **notifications** (`POST_NOTIFICATIONS`, for session reminders/enrollment alerts), **exact alarms** (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`, for 15-min session reminders)
- [x] Lurniq Plus subscription screen ships as **"Coming soon"** — no Play Billing wired, no money moves (entitlement model ready: `Entitlement` + `AppStore.setEntitlement()`)
- [ ] **User-side:** install the release AAB/APK on a real device and confirm: cold start, sign-up, post creation, lesson capture, task CRUD, admin passcode gate

## Explicitly NOT done (do not claim)

- No keystore is generated or committed by this repo — the keystore step above is entirely user-side.
- The CI release AAB without the four secrets is **debug-signed**: a performance/size reference, **not** for Play upload.
- Phase 1 has no real backend, payments, or push — the Data safety form must describe the *current* build honestly at each release.
- v2 adds: local notifications (on-device), user-provided AI key (sent to the user's AI provider only), demo-mode messaging (on-device), draft legal documents (lawyer review required before payments).
