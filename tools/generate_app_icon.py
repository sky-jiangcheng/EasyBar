from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path("Sources/MacStatusApp/Resources/Assets.xcassets/AppIcon.appiconset")
SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size - 1, size - 1), radius=radius, fill=255)
    return mask


def draw_icon(size: int) -> Image.Image:
    scale = size / 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    content = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(content)

    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(24 + 20 * t)
        g = int(102 + 74 * t)
        b = int(170 + 26 * t)
        draw.line((0, y, size, y), fill=(r, g, b, 255))

    pad = int(138 * scale)
    panel = (pad, int(250 * scale), size - pad, int(760 * scale))
    draw.rounded_rectangle(panel, radius=int(80 * scale), fill=(255, 255, 255, 42), outline=(255, 255, 255, 96), width=max(1, int(10 * scale)))

    cx = size // 2
    clock_r = int(142 * scale)
    cy = int(420 * scale)
    draw.ellipse((cx - clock_r, cy - clock_r, cx + clock_r, cy + clock_r), fill=(255, 255, 255, 226))
    draw.line((cx, cy, cx, cy - int(90 * scale)), fill=(26, 63, 112, 255), width=max(2, int(24 * scale)))
    draw.line((cx, cy, cx + int(78 * scale), cy + int(42 * scale)), fill=(26, 63, 112, 255), width=max(2, int(24 * scale)))

    bar_y = int(635 * scale)
    for index, width in enumerate((250, 360, 190)):
        x = int((size - width * scale) / 2)
        y = bar_y + int(index * 58 * scale)
        draw.rounded_rectangle((x, y, x + int(width * scale), y + int(24 * scale)), radius=int(12 * scale), fill=(255, 255, 255, 210))

    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", int(118 * scale))
    except OSError:
        font = ImageFont.load_default()
    text = "MS"
    bbox = draw.textbbox((0, 0), text, font=font)
    draw.text((int((size - (bbox[2] - bbox[0])) / 2), int(115 * scale)), text, fill=(255, 255, 255, 238), font=font)

    image.alpha_composite(content)
    mask = rounded_rect_mask(size, int(214 * scale))
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(image, (0, 0), mask)
    return result


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for filename, size in SIZES.items():
        draw_icon(size).save(OUT / filename)


if __name__ == "__main__":
    main()
