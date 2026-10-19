# Lurniq — A smarter way to learn.

A global student learning & study app (native Flutter, Android-first):

- **Tutor** — open tutoring marketplace directory (Phase 1: seeded demo tutors, browse + filter; registration/courses/bookings in Phase 3)
- **Newsfeed** — student learning community (questions, discussions, notes, resources, study groups)
- **Add Post** — composer with preview, study-group invitations, resource sharing
- **Planner** — subject folders, lesson photo capture, task manager with calendar/weekly/list views
- **Profile** — identity, privacy controls, activity, messaging-ready (Phase 4), settings

> **Demo mode:** Phase 1 runs fully on-device. Accounts, posts, lessons, and
> tasks live in the app's private storage — no account, server, or payment
> provider is involved yet. Anything seeded is badged **DEMO** in the UI and
> can be cleared from Settings → Reset demo content.

## Project status

| Phase | Scope | Status |
|---|---|---|
| 1 — Core app | Auth, 5 tabs, newsfeed, add post, planner (folders + lesson capture + tasks) | ✅ shipped as debug APK |
| 2 — Learning tools | OCR text extraction, AI study help, task-from-photo, push reminders | 🔲 planned |
| 3 — Tutor marketplace | Tutor registration, recorded courses, enrollment, reviews | 🔲 planned |
| 4 — Paid services | Live tutoring bookings, group study upgrades, messaging, payments + 15% commission, payouts/refunds | 🔲 planned |
| 5 — Global + admin | i18n, currency conversion, full admin tooling, analytics | 🔲 planned |

## Repository layout

```
lib/
  main.dart            # crash-proof bootstrap, 5-tab nav, auth gate
  core/                # constants, strings (translation-ready), theme, utils, JSON store
  models/              # JSON-serializable data models (Firestore-compatible schema)
  data/seed.dart       # demo tutors / posts / folders (all flagged isDemo)
  store/app_store.dart # single ChangeNotifier source of truth + on-device persistence
  screens/             # auth, tutor, feed, compose, planner, profile, admin
  widgets/ui.dart      # shared widgets (avatar, cards, chips, empty states)
test/
  store_test.dart      # store-level tests for critical flows
  widget_test.dart     # end-to-end widget tests (auth, compose, planner, tutor)
android/               # applicationId com.lurniq.app, release signing config
docs/                  # privacy-policy-template.md
PLAY_RELEASE_CHECKLIST.md
```

## Build

Cloud build (GitHub Actions):

1. Push to `main` → workflow `.github/workflows/build-apk.yml` runs:
   `flutter pub get` → `flutter analyze --no-fatal-infos` → `flutter test` →
   debug APK + release AAB artifacts.
2. Download the APK artifact and publish a GitHub release for testers.

Local (analysis + tests only — APK builds run in CI):

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

### Versioning

`pubspec.yaml` `version: 1.0.0+1` → `versionName 1.0.0`, `versionCode 1`.
Bump `+N` (versionCode) on **every** Play release; bump the name for
user-visible releases. Never reuse a versionCode.

### Release signing (Google Play path)

The upload keystore is **never** committed. Two inputs are supported
(`android/app/build.gradle.kts`):

1. `android/keystore.properties` (local, git-ignored):
   `storeFile`, `storePassword`, `keyAlias`, `keyPassword`
2. CI secrets: `LURNIQ_KEYSTORE_BASE64`, `LURNIQ_STORE_PASSWORD`,
   `LURNIQ_KEY_ALIAS`, `LURNIQ_KEY_PASSWORD` (see workflow)

Without either, release builds fall back to **debug signing** — fine for
testing, **not** for Play upload. Full steps:
[PLAY_RELEASE_CHECKLIST.md](PLAY_RELEASE_CHECKLIST.md).

## Admin dashboard

Triple-tap the **Profile** tab icon → admin login. Passcode: `482917`
(documented here, repo-private — never shown inside the app UI).
Change it before any production use (`lib/core/constants.dart` →
`C.adminPasscode`).

Behind the gate: content reports, announcements, commission setting,
tutor-interest list, audit log, and Phase 5 placeholders. **Every admin
action is written to the audit log.**

> ⚠️ On this demo build the dashboard is passcode-gated. Production
> deployments **must** enforce administrator roles server-side
> (Firebase custom claims or equivalent) — a hidden gesture + passcode
> alone is not real protection.

## Integration points (Phases 2–5)

Marked in code with `[BACKEND]`, `[PAYMENTS]`, `[AI]`, `[PUSH]`:

| Need | Phase | What's required (user-side) |
|---|---|---|
| Real accounts + cloud sync | 2/5 | Firebase project (Auth + Firestore in `asia-southeast1` or nearest); replace `JsonBox` persistence in `AppStore.load`/`_saveNow`; no `firebase_*` deps are bundled yet |
| OCR text extraction | 2 | On-device ML Kit (`google_mlkit_text_recognition`) or a cloud OCR API key; `Lesson` model already reserves the field |
| AI study assistant | 2 | AI provider API key — a Google AI Studio (Gemini) key works via the OpenAI-compatible endpoint; never present demo text as AI output |
| Push reminders | 2 | `flutter_local_notifications` + exact-alarm permission rationale; reminder times are already stored |
| Payments + payouts | 4 | Payment provider account (e.g. Stripe/PayMongo), payout rules, tax handling; commission math already centralized (`commissionRate`, admin-adjustable, audit-logged) |
| Lurniq Plus billing | 4 | Google Play Billing; entitlement model already in place — see below |
| Messaging | 4 | Moderation pipeline first; Phase 1 ships **no** DMs by design |
| i18n | 5 | All strings live in `lib/core/strings.dart` — add a locale catalog |

**Rules that stay true in every phase:** no fake buttons (every control does
something real); no simulated money shown as real; verification labels are
always honest (`unverified` / `ID verified` / `credential checked` with
plain-language explanations); minors get restricted messaging and no precise
home addresses in study-group locations.

### Lurniq Plus (subscription) — Play Billing wiring

Tiers: **Free** (full app; AI via user's own key or 5 demo questions/day),
**Plus ₱149/month** and **Plus ₱999/year** (unlimited AI, no key needed
once server-side, early access, supporter badge). Subscribe buttons are
marked **"Coming soon"** and move no money until Google Play Billing is
wired (needs the user's Play Console + payments phase).

The entitlement model is already structured so billing plugs in without
refactoring:

- `Entitlement` (`lib/models/models.dart`): `plan` (`free`/`plus`),
  `source` (`none`/`demo`/`play_billing`), `plusExpiresAt`; `isPlus`
  honors expiry.
- `AppStore.setEntitlement()` — the **single** method Play Billing calls
  after a purchase is verified. No call site changes needed.
- `AppStore.isPlus` / `aiUnlimited` / `demoAiQuotaRemaining()` /
  `consumeDemoAiQuota()` — the AI helper already gates on these.
- Prices: `PlusCatalog` (PHP base, approximate USD display honoring the
  user's currency preference).

## Performance notes

- All feeds/lists use lazy builders (`ListView.builder`, `ReorderableListView.builder`).
- Post/lesson images are downscaled at capture (`maxWidth 1600`, quality 85)
  and decoded with capped `cacheWidth` in lists — feeds never hold
  full-resolution bitmaps.
- Persistence writes are debounced (500 ms) and go through temp-file + rename.
- Debug APKs are inherently slower (no tree-shaking, checked mode). The
  **release AAB** artifact is the performance reference; compare on that
  before judging speed.

## Privacy & safety

- Camera/photos permission is requested **at point of need** with a
  plain-language rationale; manifest declares no location, no contacts.
- Users choose per-field profile privacy (public / followers / private);
  blocking hides a user's posts and comments from the blocker.
- Study groups never ask for precise home addresses (in-app safety copy).

## Legal (drafts — not legal advice)

The in-app **Terms of Service**, **Privacy Policy**, and **Tutor
Agreement** (`lib/screens/legal/legal_screens.dart`) are good-faith
**drafts for review, not legal advice and not final**. Every surface
carries that banner. Key points of the drafts:

- Lurniq is a marketplace; tutors are independent, not employees.
- 15% platform commission on paid courses/bookings, shown before payment.
- Tutor payouts: 7-day clearing, \$20 minimum, via payment provider.
- Refund windows: >24h full, <24h 50% (student cancel); tutor cancel =
  full refund.
- Tutors must be 18+; students 13+ with parental consent for paid
  features; adult–minor safeguards throughout.
- Tutors handle their own taxes.

Enforcement in code: sign-up requires ToS + Privacy Policy acceptance
(version + timestamp stored on the account); creating a course or live
session requires accepting the current Tutor Agreement
(`AppStore.tutorAgreementAccepted`, version-gated). Bumping a version in
`lib/legal/legal_versions.dart` forces re-acceptance.

**Do not accept real payments before the lawyer-review gate in
[LEGAL_CHECKLIST.md](LEGAL_CHECKLIST.md) is cleared** (BIR registration,
Data Privacy Act/NPC, Play Data Safety form, Stripe Connect/payouts,
tutor age verification).
- Academic-integrity microcopy is built into the question composer and
  question threads (explanations over copy-paste answers).
