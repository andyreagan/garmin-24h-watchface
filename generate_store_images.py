#!/usr/bin/env python3
"""Generate Connect IQ store images from the simulator screenshot.

Creates:
  1. store-banner.png  — 1440x720 mobile banner ad (max 2048KB)
  2. store-cover.png   — 500x500 cover image (max 300KB)

Requires: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SCREENSHOT = os.path.join(SCRIPT_DIR, "screenshot.png")
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"
BG_COLOR = (20, 20, 25)


def extract_watch(screenshot):
    """Extract the watch from the simulator screenshot, replacing white background with dark."""
    w, h = screenshot.size
    # The watch body is roughly in the center of the screenshot
    # Crop a square around just the watch (excluding title bar and status bar)
    crop_size = 760
    cx = w // 2
    cy = 440
    left = cx - crop_size // 2
    top = cy - crop_size // 2
    watch = screenshot.crop((left, top, left + crop_size, top + crop_size))

    # Replace white/near-white background pixels with our dark bg
    watch = watch.convert("RGBA")
    pixels = watch.load()
    for y in range(watch.height):
        for x in range(watch.width):
            r, g, b, a = pixels[x, y]
            # White or near-white background
            if r > 230 and g > 230 and b > 230:
                pixels[x, y] = (BG_COLOR[0], BG_COLOR[1], BG_COLOR[2], 255)

    return watch


def create_banner(watch):
    """Create 1440x720 banner image for mobile advertising."""
    banner = Image.new("RGB", (1440, 720), BG_COLOR)
    draw = ImageDraw.Draw(banner)

    # Place watch on the left side, sized to fill height with padding
    watch_resized = watch.resize((680, 680), Image.LANCZOS)
    banner.paste(watch_resized, (40, 20), watch_resized)

    # Text on the right
    try:
        title_font = ImageFont.truetype(FONT_PATH, 64, index=1)
        subtitle_font = ImageFont.truetype(FONT_PATH, 32, index=0)
        detail_font = ImageFont.truetype(FONT_PATH, 24, index=0)
    except Exception:
        title_font = subtitle_font = detail_font = ImageFont.load_default()

    text_x = 800

    draw.text((text_x, 200), "24-Hour", font=title_font, fill=(255, 255, 255))
    draw.text((text_x, 275), "Watch Face", font=title_font, fill=(255, 255, 255))
    draw.text((text_x, 380), "See your full day at a glance", font=subtitle_font, fill=(180, 180, 180))

    features = [
        "• Single-rotation 24h dial",
        "• Bold, readable hour numbers",
        "• Optional minute hand & date",
    ]
    y = 450
    for feat in features:
        draw.text((text_x, y), feat, font=detail_font, fill=(140, 140, 140))
        y += 36

    out = os.path.join(SCRIPT_DIR, "store-banner.png")
    banner.save(out, optimize=True)
    size_kb = os.path.getsize(out) / 1024
    print(f"✅ Banner: {out} ({banner.size[0]}x{banner.size[1]}, {size_kb:.0f}KB)")
    if size_kb > 2048:
        out_jpg = os.path.join(SCRIPT_DIR, "store-banner.jpg")
        banner.save(out_jpg, "JPEG", quality=85, optimize=True)
        print(f"   ⚠️ PNG over 2048KB, saved JPEG: {os.path.getsize(out_jpg)/1024:.0f}KB")


def create_cover(watch):
    """Create 500x500 cover image for web/mobile listing."""
    cover = Image.new("RGB", (500, 500), BG_COLOR)

    # Fill the square with the watch
    watch_resized = watch.resize((480, 480), Image.LANCZOS)
    cover.paste(watch_resized, (10, 10), watch_resized)

    out = os.path.join(SCRIPT_DIR, "store-cover.png")
    cover.save(out, optimize=True)
    size_kb = os.path.getsize(out) / 1024
    print(f"✅ Cover:  {out} ({cover.size[0]}x{cover.size[1]}, {size_kb:.0f}KB)")
    if size_kb > 300:
        out_jpg = os.path.join(SCRIPT_DIR, "store-cover.jpg")
        cover.save(out_jpg, "JPEG", quality=75, optimize=True)
        print(f"   ⚠️ PNG over 300KB, saved JPEG: {os.path.getsize(out_jpg)/1024:.0f}KB")


def main():
    screenshot = Image.open(SCREENSHOT)
    print(f"Source: {screenshot.size[0]}x{screenshot.size[1]}")
    print()

    watch = extract_watch(screenshot)
    create_banner(watch)
    create_cover(watch)
    print("\nDone!")


if __name__ == "__main__":
    main()
