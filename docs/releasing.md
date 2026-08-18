# Releasing & Updating Slove

This document explains how Slove is versioned, built, tested, and shipped to
testers and to the stores once released.

## The core constraint: content is bundled

Game content lives in `lib/content/*.json` and is loaded via
`rootBundle.loadString()`. There is **no backend and no remote content fetch** —
this is an explicit Non-Goal (see `ROADMAP.md`).

> **Every bug fix *and* every content change ships as a new app release.**
> There is no way to push new exercises without going through the store.

## Versioning

`pubspec.yaml` holds the marketing version:

```yaml
version: 1.0.0+1
```

`MAJOR.MINOR.PATCH+buildNumber`:

| Change | Bump |
|---|---|
| Bug fix | patch — `1.0.1+1` |
| New content / feature | minor — `1.1.0+1` |
| Breaking / major redesign | major — `2.0.0+1` |

The build number (`+N`) is **managed automatically in CI** from
`GITHUB_RUN_ID` — a unique, always-increasing number per workflow run, shared
across both the staging and production workflows, so it is monotonic and never
collides between the two tracks. You only
ever edit the `X.Y.Z` part; leave `+N` alone.

## Branch-driven workflow

Two long-lived branches drive releases:

| Branch | Purpose | Deploys to |
|---|---|---|
| `staging` | test builds for you and your testers | TestFlight (internal testers) + Play internal testing |
| `master` | production | TestFlight + App Store Connect, Play production |

Everyday flow:

```text
feature/xxx ──PR──▶ staging ──push──▶ test builds go out automatically
                        │
                        └──merge──▶ master ──push──▶ production goes out automatically
```

1. Work on a feature branch; open a PR into `staging`.
2. Merge to `staging` → `deploy-staging.yml` runs and ships test builds to
   TestFlight and Play internal testing automatically.
3. When happy, merge `staging` into `master` (push to `master`) →
   `deploy-prod.yml` runs and ships to production automatically.

> **Note:** pushing directly to `master` deploys to production — there is no
> manual approval gate. Treat `master` as the live release.

## CI workflows

| Workflow | Trigger | Result |
|---|---|---|
| `ci.yml` | push to feature branches, and all PRs | analyze + unit/widget tests + unsigned builds (sanity gate) |
| `deploy-staging.yml` | push to `staging` | signed Android AAB → Play internal testing; signed IPA → TestFlight |
| `deploy-prod.yml` | push to `master` | signed Android AAB → Play production; signed IPA → App Store Connect |

Signing secrets are configured per `RELEASE_SIGNING.md`; never commit them.

### Screenshot integration workflow

`integration_test/screenshot_test.dart` captures store-review screenshots on a
connected device or emulator. It is not run by `flutter test` or by CI because
it depends on device screenshots and is an editorial asset workflow, not a
release gate. Run it explicitly with:

```bash
flutter drive --driver test_driver/integration_test.dart \
  --target integration_test/screenshot_test.dart
```

## Getting changes to testers

### iOS — TestFlight

`deploy-staging.yml` uploads every `staging` build to TestFlight automatically.

- **Internal testers** (up to 100 Apple accounts, added under App Store Connect →
  Users and Access) receive every uploaded build **immediately — no review**.
  This is the fast lane for your own phone and a small team.
- **External testers** (up to 10,000, invited by email/TestFlight link) receive
  builds after the **first build of a new app version passes Beta App Review**.
  Subsequent builds of an already-approved version do not need re-review.

### Android — internal testing

`deploy-staging.yml` uploads every `staging` build to the Play internal-testing
track automatically (via `r0adkll/upload-google-play`).

- Add tester emails (or a Google Group) once in Play Console → Testing →
  Internal testing.
- Testers opt in via the invite link, then install through Google Play.
- Internal testing publishes within minutes and needs **no review**.

The app must have completed initial Play setup (app created, Data safety form,
etc.) before the first upload.

## Shipping a full production release

1. Bump the `X.Y.Z` version in `pubspec.yaml` (build number is automatic).
2. Merge `staging` → `master` (or push to `master`). `deploy-prod.yml` builds
   signed artifacts and:
   - **Android**: uploads the AAB to the Play production track — live after
     Google's automatic review.
   - **iOS**: uploads the IPA to App Store Connect. Then, in App Store Connect,
     click **Submit for Review** (the one remaining manual step — Apple requires
     a human to submit and always reviews). Optionally promote to TestFlight
     external testers at the same time.

## Store review notes

- **App Store** reviews every production submission. Internal TestFlight builds
  skip review; external beta and production builds are reviewed.
- **Google Play** publishes production updates without a manual review gate, but
  the app must remain policy-compliant.
- Both stores require the version string and privacy disclosures (in
  `store_listings/`) to stay accurate — update them whenever analytics or data
  collection changes.

## One-time prerequisites

- `RELEASE_SIGNING.md` — signing secrets and the Android Play service account.
- The Play service-account JSON secret (`ANDROID_PLAY_SERVICE_ACCOUNT_JSON`) must
  exist before Android uploads can run.

## Related docs

- `RELEASE_SIGNING.md` — signing secrets and setup
- `RELEASE_READINESS_REPORT.md` — release status tracked via GitHub Issues
- `ROADMAP.md` — milestones and Non-Goals
