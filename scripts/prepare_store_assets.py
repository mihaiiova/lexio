"""Prepare platform-sized store assets from the checked-in device captures."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "screenshots"
IPAD_SOURCE = ROOT / "store_assets" / "source" / "ipad_pro_13"
OUTPUT = ROOT / "store_assets"

CAPTURES = [
    "01_home",
    "02_grammar",
    "03_vocabulary",
    "04_idioms",
    "05_spot",
    "06_summary",
]


def load_font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(ROOT / "assets" / "fonts" / name, size)


def save_capture(source: Path, destination: Path, size: tuple[int, int]) -> None:
    with Image.open(source) as image:
        fitted = ImageOps.fit(image.convert("RGB"), size, method=Image.Resampling.LANCZOS)
        destination.parent.mkdir(parents=True, exist_ok=True)
        fitted.save(destination, optimize=True)


def save_icon(source: Path, destination: Path, size: tuple[int, int]) -> None:
    with Image.open(source) as image:
        image.convert("RGBA").resize(size, Image.Resampling.LANCZOS).save(destination, optimize=True)


def create_feature_graphic(destination: Path) -> None:
    size = (1024, 500)
    image = Image.new("RGB", size, "#F2F3F5")
    draw = ImageDraw.Draw(image)

    shadow = (56, 65, 81, 26)
    shadow_layer = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_draw.rounded_rectangle((690, 54, 930, 294), radius=48, fill=shadow)
    image = Image.alpha_composite(image.convert("RGBA"), shadow_layer)
    draw = ImageDraw.Draw(image)

    icon_path = ROOT / "assets" / "brand_icons" / "android_play_store.png"
    with Image.open(icon_path) as icon:
        icon = icon.convert("RGBA").resize((240, 240), Image.Resampling.LANCZOS)
        image.alpha_composite(icon, (690, 42))

    draw = ImageDraw.Draw(image)
    draw.text((72, 82), "Slove", font=load_font("NoticiaText-Bold.ttf", 82), fill="#17191C")
    draw.text(
        (76, 190),
        "Joacă-te cu limba română.",
        font=load_font("NoticiaText-Regular.ttf", 34),
        fill="#62666D",
    )
    draw.text(
        (78, 302),
        "GRAMATICĂ  •  VOCABULAR  •  EXPRESII  •  ATENȚIE",
        font=load_font("NoticiaText-Bold.ttf", 16),
        fill="#4588E0",
    )

    for index, color in enumerate(("#4588E0", "#E04B40", "#8ABAC5", "#E6981A")):
        draw.ellipse((78 + index * 32, 365, 96 + index * 32, 383), fill=color)

    destination.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(destination, quality=95, optimize=True)


def main() -> None:
    for name in CAPTURES:
        save_capture(
            SCREENSHOTS / f"{name}.png",
            OUTPUT / "app_store" / "iphone_6_7" / f"{name}.png",
            (1290, 2796),
        )
        save_capture(
            SCREENSHOTS / f"{name}.png",
            OUTPUT / "app_store" / "iphone_6_5" / f"{name}.png",
            (1242, 2688),
        )
        save_capture(
            IPAD_SOURCE / f"{name}.png",
            OUTPUT / "app_store" / "ipad_12_9" / f"{name}.png",
            (2048, 2732),
        )
        save_capture(
            IPAD_SOURCE / f"{name}.png",
            OUTPUT / "app_store" / "ipad_11" / f"{name}.png",
            (1668, 2388),
        )
        save_capture(
            SCREENSHOTS / f"{name}.png",
            OUTPUT / "google_play" / "phone" / f"{name}.png",
            (1320, 2868),
        )
        save_capture(
            IPAD_SOURCE / f"{name}.png",
            OUTPUT / "google_play" / "tablet" / f"{name}.png",
            (2064, 2752),
        )

    save_icon(
        ROOT / "assets" / "brand_icons" / "android_play_store.png",
        OUTPUT / "google_play" / "app_icon_512.png",
        (512, 512),
    )
    save_icon(
        ROOT / "assets" / "brand_icons" / "ios_1024.png",
        OUTPUT / "app_store" / "app_icon_1024.png",
        (1024, 1024),
    )
    create_feature_graphic(OUTPUT / "google_play" / "feature_graphic_1024x500.png")


if __name__ == "__main__":
    main()
