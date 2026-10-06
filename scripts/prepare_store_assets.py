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


def save_play_phone_capture(source: Path, destination: Path) -> None:
    with Image.open(source) as image:
        fitted = ImageOps.fit(
            image.convert("RGB"),
            (1320, 2640),
            method=Image.Resampling.LANCZOS,
        )
        destination.parent.mkdir(parents=True, exist_ok=True)
        fitted.save(destination, optimize=True)


def save_icon(
    source: Path, destination: Path, size: tuple[int, int], *, opaque: bool = False
) -> None:
    with Image.open(source) as image:
        mode = "RGB" if opaque else "RGBA"
        image.convert(mode).resize(size, Image.Resampling.LANCZOS).save(destination, optimize=True)


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


def create_app_store_creative_assets(directory: Path) -> None:
    games = (
        ("Găsește greșeala", "#E6981A"),
        ("Corect sau greșit?", "#4588E0"),
        ("Ce înseamnă?", "#E04B40"),
        ("Vorba vine", "#8ABAC5"),
    )

    header = Image.new("RGB", (3840, 1646), "#F2F3F5")
    draw = ImageDraw.Draw(header)
    draw.text((250, 380), "Slove", font=load_font("NoticiaText-Bold.ttf", 320), fill="#17191C")
    draw.text(
        (270, 790),
        "Joacă-te cu limba română.",
        font=load_font("NoticiaText-Regular.ttf", 102),
        fill="#62666D",
    )
    for index, (title, color) in enumerate(games):
        x = 2100 + (index % 2) * 765
        y = 300 + (index // 2) * 555
        draw.rounded_rectangle((x, y, x + 700, y + 470), radius=56, fill="white")
        draw.rounded_rectangle((x + 54, y + 58, x + 170, y + 70), radius=6, fill=color)
        draw.text(
            (x + 54, y + 160),
            title,
            font=load_font("NoticiaText-Bold.ttf", 58),
            fill="#17191C",
        )

    search = Image.new("RGB", (1920, 1280), "#F2F3F5")
    draw = ImageDraw.Draw(search)
    draw.text((120, 95), "Slove", font=load_font("NoticiaText-Bold.ttf", 174), fill="#17191C")
    draw.text(
        (130, 345),
        "Joacă-te cu limba română.",
        font=load_font("NoticiaText-Regular.ttf", 74),
        fill="#62666D",
    )
    for index, (title, color) in enumerate(games):
        x = 120 + (index % 2) * 860
        y = 540 + (index // 2) * 340
        draw.rounded_rectangle((x, y, x + 800, y + 275), radius=42, fill="white")
        draw.rounded_rectangle((x + 40, y + 36, x + 135, y + 47), radius=5, fill=color)
        draw.text(
            (x + 40, y + 93),
            title,
            font=load_font("NoticiaText-Bold.ttf", 63),
            fill="#17191C",
        )

    directory.mkdir(parents=True, exist_ok=True)
    header.save(directory / "header_3840x1646.png", optimize=True)
    search.save(directory / "search_results_1920x1280.png", optimize=True)


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
            SCREENSHOTS / f"{name}.png",
            OUTPUT / "app_store" / "iphone_dynamic_island_medium" / f"{name}.png",
            (1179, 2556),
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
        save_play_phone_capture(
            SCREENSHOTS / f"{name}.png",
            OUTPUT / "google_play" / "phone" / f"{name}.png",
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
        opaque=True,
    )
    create_feature_graphic(OUTPUT / "google_play" / "feature_graphic_1024x500.png")
    create_app_store_creative_assets(OUTPUT / "app_store" / "creative_assets")


if __name__ == "__main__":
    main()
