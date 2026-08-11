# Release Smoke Test Checklist

> **Tracking:** Progress is tracked in [#25](https://github.com/mihaiiova/lexio/issues/25). Use this document when running through the tests.

**Version:** 1.0.0+1
**Date:** ____ / ____ / 2026
**Tester:** ______________

## Prerequisites

- [ ] All CI checks passing on main branch
- [ ] All tests passing locally (`flutter analyze && flutter test`)
- [ ] Release builds produced by CI or locally

## Web (Desktop Browser)

### Chrome
- [ ] Public Slove website loads without errors
- [ ] Home screen shows 4 games with correct Romanian text
- [ ] Complete a Grammar round (15 questions) — correct/wrong answers, summary, replay
- [ ] Complete a Vocabulary round (10 questions) — options, correct highlighting, explanation
- [ ] Complete an Idioms round (10 questions) — expression display, meaning matching
- [ ] Complete a Spot round (5 texts) — tap mistakes, timer counts down from 60s, summary
- [ ] Check Spot timer: open browser DevTools, verify it keeps counting during gameplay
- [ ] Navigate back from each game to home screen
- [ ] Refresh page — app reloads to home screen
- [ ] Privacy page opens inside the app

### Safari
- [ ] Same checks as Chrome (basic smoke: loading, one game)

### Mobile Browser (Chrome/Safari)
- [ ] Site loads on phone
- [ ] One game completes successfully
- [ ] PWA "Add to Home Screen" works (Android Chrome)
- [ ] PWA launches from home screen as standalone app

## iOS

### iPhone (real device)
- [ ] App installs from TestFlight
- [ ] Branded app icon visible on home screen
- [ ] Launch screen: white background, no Flutter placeholder
- [ ] Home screen shows 4 games
- [ ] Grammar game: 15 questions, correct/incorrect, summary, replay
- [ ] Vocabulary game: 10 questions, options, correct highlight
- [ ] Idioms game: 10 questions, expression, meaning
- [ ] Spot game: 5 texts, 60s timer, tap mistakes, summary
- [ ] **Spot timer test**: Start Spot, switch to another app for 10+ seconds, return — timer should have decreased by ~10s (deadline-based)
- [ ] **Spot timer test**: Let timer expire on text 1 — should auto-advance to text 2
- [ ] **Spot timer test**: Let timer expire on text 5 — should show summary
- [ ] **Background test**: Background the app for 30 seconds during any game, return — game should resume correctly
- [ ] Navigation: back button from each game returns to home
- [ ] Offline test: enable airplane mode, launch app, play any game — should work fully
- [ ] Privacy page opens inside the app
- [ ] Enlarged text: increase system font size, verify text scales without overflow
- [ ] Screen reader (VoiceOver): basic navigation works through home and one game

### iPad (real device)
- [ ] App installs from TestFlight
- [ ] All 4 games complete successfully
- [ ] Landscape orientation works correctly
- [ ] No layout issues at tablet sizes

## Android

### Phone (real device)
- [ ] App installs from Google Play (internal testing track) or sideloaded AAB
- [ ] Branded launcher icon visible
- [ ] Launch screen: blue branded splash, no Flutter template
- [ ] Home screen shows 4 games
- [ ] Grammar game: full round, summary, replay
- [ ] Vocabulary game: full round
- [ ] Idioms game: full round
- [ ] Spot game: 5 texts, 60s timer, summary
- [ ] **Spot timer test**: Background/resume timer accuracy
- [ ] Navigation: back button from each game
- [ ] Offline test: airplane mode, play all games
- [ ] Enlarged text: increase system font size
- [ ] Screen reader (TalkBack): basic navigation

### Tablet
- [ ] App installs
- [ ] All 4 games complete successfully
- [ ] No layout issues at tablet sizes

## Sign-off

| Check | Status |
|---|---|
| All CI/build checks pass | ☐ |
| iOS smoke test (iPhone) | ☐ |
| iOS smoke test (iPad) | ☐ |
| Android smoke test (phone) | ☐ |
| Android smoke test (tablet) | ☐ |
| Web smoke test (desktop) | ☐ |
| Web smoke test (mobile) | ☐ |
| Offline mode verified | ☐ |
| Background/resume verified | ☐ |
| Signed artifacts match tested builds | ☐ |
| No critical runtime errors | ☐ |

### Decision

☐ **GO** — Proceed to store submission
☐ **NO-GO** — Issues found (document below):

_______________________________________________
_______________________________________________
_______________________________________________

**Sign-off date:** ____ / ____ / 2026
**Sign-off by:** ______________
