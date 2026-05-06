#!/usr/bin/env python3
"""Generate Connect IQ store images (banner + cover).

Renders the watch face directly via the screen-image generator so that the
store assets reflect the current v2 feature set without relying on a fresh
simulator screenshot.

Creates:
  1. store-banner.png  — 1440x720 mobile banner ad (max 2048KB)
  2. store-cover.png   — 500x500 cover image (max 300KB)

Requires: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

from generate_screen_images import render_watchface

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"
BG_COLOR = (20, 20, 25)


def hero_watch(size=720):
    """Render a hero shot of the watch face for store assets."""
    img = render_watchface(
        hour=14,
        minute=22,
        date_str="Mar 27",
        show_minute_hand=True,
        show_date=True,
        noon_at_top=True,
        five_min_color=5,        # Orange
        show_battery=True,
        battery_pct=82,
    ).convert("RGBA")
    # Mask to a circle so it reads as a watch face on a dark background.
    mask = Image.new("L", img.size, 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.ellipse((0, 0, img.size[0], img.size[1]), fill=255)
    img.putalpha(mask)
    return img.resize((size, size), Image.LANCZOS)


def create_banner():
    banner = Image.new("RGB", (1440, 720), BG_COLOR)
    draw = ImageDraw.Draw(banner)

    watch = hero_watch(680)
    banner.paste(watch, (40, 20), watch)

    try:
        title_font = ImageFont.truetype(FONT_PATH, 64, index=1)
        subtitle_font = ImageFont.truetype(FONT_PATH, 32, index=0)
        detail_font = ImageFont.truetype(FONT_PATH, 24, index=0)
    except Exception:
        title_font = subtitle_font = detail_font = ImageFont.load_default()

    text_x = 800
    draw.text((text_x, 180), "24-Hour", font=title_font, fill=(255, 255, 255))
    draw.text((text_x, 255), "Watch Face", font=title_font, fill=(255, 255, 255))
    draw.text((text_x, 360), "See your full day at a glance", font=subtitle_font, fill=(180, 180, 180))

    features = [
        "• Single-rotation 24h dial",
        "• Noon-at-top option",
        "• 5-minute tick highlights (5 colors)",
        "• Battery %, date, optional minute hand",
    ]
    y = 430
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


def create_cover():
    cover = Image.new("RGB", (500, 500), BG_COLOR)
    watch = hero_watch(480)
    cover.paste(watch, (10, 10), watch)

    out = os.path.join(SCRIPT_DIR, "store-cover.png")
    cover.save(out, optimize=True)
    size_kb = os.path.getsize(out) / 1024
    print(f"✅ Cover:  {out} ({cover.size[0]}x{cover.size[1]}, {size_kb:.0f}KB)")
    if size_kb > 300:
        out_jpg = os.path.join(SCRIPT_DIR, "store-cover.jpg")
        cover.save(out_jpg, "JPEG", quality=75, optimize=True)
        print(f"   ⚠️ PNG over 300KB, saved JPEG: {os.path.getsize(out_jpg)/1024:.0f}KB")


def main():
    create_banner()
    create_cover()
    print("\nDone!")


if __name__ == "__main__":
    main()
