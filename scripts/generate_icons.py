#!/usr/bin/env python3
"""Generate branded Slove app icons using Pillow.

Creates a clean, typographic icon: white "S" in NoticiaText style on primary blue.
Output to assets/brand_icons/ for use with flutter_launcher_icons or manual placement.
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "brand_icons"
OUT.mkdir(parents=True, exist_ok=True)

BLUE = (69, 136, 224)        # LexioColors.primary
WHITE = (255, 255, 255)
FONT = ROOT / "assets" / "fonts" / "NoticiaText-Bold.ttf"

sizes = {
    # iOS
    "ios_20@2x": 40,
    "ios_20@3x": 60,
    "ios_29@2x": 58,
    "ios_29@3x": 87,
    "ios_40@2x": 80,
    "ios_40@3x": 120,
    "ios_60@2x": 120,
    "ios_60@3x": 180,
    "ios_20_ipad": 20,
    "ios_20_ipad@2x": 40,
    "ios_29_ipad": 29,
    "ios_29_ipad@2x": 58,
    "ios_40_ipad": 40,
    "ios_40_ipad@2x": 80,
    "ios_76_ipad": 76,
    "ios_76_ipad@2x": 152,
    "ios_83.5_ipad@2x": 167,
    "ios_1024": 1024,
    # Android
    "android_mdpi": 48,
    "android_hdpi": 72,
    "android_xhdpi": 96,
    "android_xxhdpi": 144,
    "android_xxxhdpi": 192,
    "android_play_store": 512,
    # macOS
    "macos_16": 16,
    "macos_32": 32,
    "macos_64": 64,
    "macos_128": 128,
    "macos_256": 256,
    "macos_512": 512,
    "macos_1024": 1024,
    # Web / PWA
    "web_192": 192,
    "web_512": 512,
    "web_maskable_192": 192,
    "web_maskable_512": 512,
    "favicon_16": 16,
    "favicon_32": 32,
    "favicon_48": 48,
    "favicon_64": 64,
}

def draw_icon(size, name):
    scale = 4
    canvas_size = size * scale
    img = Image.new("RGBA", (canvas_size, canvas_size), BLUE + (255,))
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(canvas_size * 0.82))
    bounds = draw.textbbox((0, 0), "S", font=font)
    width = bounds[2] - bounds[0]
    height = bounds[3] - bounds[1]
    position = (
        (canvas_size - width) / 2 - bounds[0],
        (canvas_size - height) / 2 - bounds[1],
    )
    draw.text(position, "S", font=font, fill=WHITE)
    img = img.resize((size, size), Image.Resampling.LANCZOS)

    out = OUT / f"{name}.png"
    img.save(out, "PNG")
    print(f"  {out.name} ({size}x{size})")

print("Generating brand icons...")
for name, size in sizes.items():
    draw_icon(size, name)

# Generate adaptive icon foreground (Android) - center within 108dp safe zone
SAFE = 108
SCALE = 4
fg = Image.new("RGBA", (SAFE * SCALE, SAFE * SCALE), (0, 0, 0, 0))
dfg = ImageDraw.Draw(fg)
font = ImageFont.truetype(FONT, int(SAFE * SCALE * 0.82))
bounds = dfg.textbbox((0, 0), "S", font=font)
width = bounds[2] - bounds[0]
height = bounds[3] - bounds[1]
position = (
    (SAFE * SCALE - width) / 2 - bounds[0],
    (SAFE * SCALE - height) / 2 - bounds[1],
)
dfg.text(position, "S", font=font, fill=WHITE)
fg = fg.resize((SAFE, SAFE), Image.Resampling.LANCZOS)
fg.save(OUT / "android_adaptive_foreground.png", "PNG")

# Android adaptive background (solid blue)
bg = Image.new("RGBA", (SAFE, SAFE), BLUE + (255,))
bg.save(OUT / "android_adaptive_background.png", "PNG")

print(f"\nIcons saved to {OUT}/")
print(f"Total: {len(sizes)} icons + adaptive foreground/background")
