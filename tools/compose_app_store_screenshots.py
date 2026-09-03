from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path("AppStoreScreenshots")
OUT_SIZE = (1280, 800)
WINDOW_BOX = (75, 205, 1116, 936)

SOURCES = [
    ("_full-01.png", "macstatus-01-dashboard-1280x800.png"),
    ("_full-02.png", "macstatus-02-search-1280x800.png"),
    ("_full-03.png", "macstatus-03-shortcuts-1280x800.png"),
]


def background() -> Image.Image:
    width, height = OUT_SIZE
    img = Image.new("RGB", OUT_SIZE, "#172021")
    draw = ImageDraw.Draw(img)
    for y in range(height):
        t = y / max(height - 1, 1)
        r = int(20 + 18 * t)
        g = int(34 + 20 * t)
        b = int(38 + 24 * t)
        draw.line((0, y, width, y), fill=(r, g, b))
    draw.ellipse((-140, -120, 460, 420), fill=(24, 105, 150))
    draw.ellipse((850, 470, 1460, 1050), fill=(43, 86, 83))
    return img.filter(ImageFilter.GaussianBlur(34))


def compose(source_name: str, output_name: str) -> None:
    full = Image.open(ROOT / source_name).convert("RGBA")
    window = full.crop(WINDOW_BOX)
    window.thumbnail((1080, 720), Image.Resampling.LANCZOS)

    canvas = background().convert("RGBA")
    shadow = Image.new("RGBA", window.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((0, 0, window.width - 1, window.height - 1), radius=20, fill=(0, 0, 0, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))

    x = (OUT_SIZE[0] - window.width) // 2
    y = (OUT_SIZE[1] - window.height) // 2
    canvas.alpha_composite(shadow, (x + 8, y + 18))
    canvas.alpha_composite(window, (x, y))
    canvas.convert("RGB").save(ROOT / output_name, quality=95)


def main() -> None:
    for source, output in SOURCES:
        compose(source, output)


if __name__ == "__main__":
    main()
