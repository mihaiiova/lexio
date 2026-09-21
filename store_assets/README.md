# Store assets

This directory contains the prepared App Store and Google Play assets for Slove.
The screenshots contain Romanian UI text and were captured from the current app
build using the integration screenshot workflow.

## Generate

From the repository root:

```bash
python3 scripts/prepare_store_assets.py
```

The script derives the platform-sized PNG files from:

- `screenshots/` — iPhone 17 Pro Max capture source
- `store_assets/source/ipad_pro_13/` — iPad Pro 13-inch simulator capture source
- `assets/brand_icons/` — approved application icons

## Asset map

| Store | Directory | Contents |
|---|---|---|
| App Store | `app_store/iphone_6_7/` | Six 1290 × 2796 screenshots |
| App Store | `app_store/iphone_6_5/` | Six 1242 × 2688 screenshots |
| App Store | `app_store/ipad_12_9/` | Six 2048 × 2732 screenshots |
| App Store | `app_store/ipad_11/` | Six 1668 × 2388 screenshots |
| Google Play | `google_play/phone/` | Six phone screenshots |
| Google Play | `google_play/tablet/` | Six high-resolution tablet screenshots |
| Google Play | `google_play/feature_graphic_1024x500.png` | Feature graphic |
| Google Play | `google_play/app_icon_512.png` | 512 × 512 icon |
| App Store | `app_store/app_icon_1024.png` | 1024 × 1024 icon |

The six screenshots are: home, grammar, vocabulary, idioms, Spot, and the
round summary. The generated files are RGB PNGs; application icons retain
transparency where required.

## Upload

The files are ready for manual upload in App Store Connect and Google Play
Console. Console submission remains manual because this repository does not
contain store credentials or store APIs.
