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

`pubspec.yaml` holds the single source of truth:

```yaml
version: 1.0.0+1
```

`MAJOR.MINOR.PATCH+buildNumber`:

| Change | Bump |
|---|---|
| Bug fix | patch — `1.0.1+1` |
| New content / feature | minor — `1.1.0+1` |
| Breaking / major redesign | major — `2.0.0+1` |

- Android takes its `versionCode` straight from the build number.
- iOS `deploy.yml` auto-increments the build number, but you must still bump the
  short version (`1.0.1`) yourself — App Store rejects identical version strings.

## CI workflows

| Workflow | Trigger | Result |
|---|---|---|
| `ci.yml` | every push / PR | analyze + test + unsigned builds (sanity check) |
| `release.yml` | git tag `v*` or manual "Run workflow" | signed Android AAB + iOS IPA artifacts |
| `deploy.yml` | manual "Run workflow" | iOS IPA → TestFlight, auto-bumps build number |

Signing secrets are configured per `RELEASE_SIGNING.md`; never commit them.

## Getting changes to testers

### iOS — TestFlight

1. Bump `version:` in `pubspec.yaml`, merge to `master`.
2. Run the **Deploy to TestFlight** workflow (Actions tab → Run workflow).
3. The build appears in App Store Connect → TestFlight. `deploy.yml` bumps the
   build number automatically and pushes the bump.

Testers:

- **Internal testers** (up to 100 Apple accounts, added under App Store Connect →
  Users and Access) receive every uploaded build **immediately — no review**.
  This is the fast lane for your own phone and a small team.
- **External testers** (up to 10,000, invited by email/TestFlight link) receive
  builds after the **first build of a new app version passes Beta App Review**.
  Subsequent builds of an already-approved version do not need re-review.

### Android — internal testing

Android has **no automated Play upload** yet, so this step is manual:

1. Bump `version:` in `pubspec.yaml`, merge to `master`.
2. Run the **Release** workflow (tag `v*` or manual) and download the signed AAB
   artifact (`lexio-android-release`).
3. In Google Play Console → your app → **Testing → Internal testing**, upload
   the AAB and add tester emails (or a Google Group).
4. Testers opt in via the invite link, then install through Google Play.

Internal testing publishes within minutes and needs **no review**. The app must
have completed initial Play setup (app created, Data safety form, etc.) before
the first upload.

## Shipping a full production release

1. Edit code/JSON, bump `version:` in `pubspec.yaml`.
2. Open a PR or merge to `master` — `ci.yml` runs analyze + tests automatically.
3. Cut a tag (or run manually):
   ```bash
   git tag v1.0.1 && git push origin v1.0.1
   ```
   This triggers `release.yml`, producing the signed AAB and IPA artifacts.
4. **iOS**: run **Deploy to TestFlight** → TestFlight → App Store review →
   promote to production.
5. **Android**: download the AAB from the `release.yml` run, upload it to the
   Google Play production (or staged rollout) track.

## Store review notes

- **App Store** reviews every production submission and each new external-beta
  version. Internal TestFlight builds skip review.
- **Google Play** publishes production updates without a manual review gate, but
  the app itself must remain policy-compliant.
- Both stores require the version string and privacy disclosures (in
  `store_listings/`) to stay accurate — update them whenever analytics or data
  collection changes.

## Related docs

- `RELEASE_SIGNING.md` — signing secrets and setup
- `RELEASE_READINESS_REPORT.md` — release status tracked via GitHub Issues
- `ROADMAP.md` — milestones and Non-Goals
