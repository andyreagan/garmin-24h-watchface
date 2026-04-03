#!/usr/bin/env python3
"""Generate Connect IQ store screen images.

Renders the watch face at different times to create store screenshots.
Screen images must be JPG, GIF, or PNG less than 150 KB.

Requires: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SIZE = 260
CENTER = SIZE // 2
RADIUS = SIZE // 2
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"
NUM_DIR = os.path.join(SCRIPT_DIR, "resources", "drawables", "numbers")


def get_xy(hour_float, r):
    angle_deg = (hour_float * 15.0) - 90.0
    angle_rad = math.radians(angle_deg)
    x = CENTER + r * math.cos(angle_rad)
    y = CENTER + r * math.sin(angle_rad)
    return x, y


def render_watchface(hour, minute, date_str, show_minute_hand=True, show_date=True):
    """Render the watch face at a given time."""
    img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Load number bitmaps
    num_images = []
    for i in range(24):
        num_images.append(Image.open(os.path.join(NUM_DIR, f"num_{i:02d}.png")).convert("RGBA"))

    # Layout
    number_radius = RADIUS - 8
    tick_outer = RADIUS - 18
    hour_tick_inner = RADIUS - 32
    quarter_tick_inner = RADIUS - 25

    # Number bitmaps
    for i in range(24):
        bmp = num_images[i]
        px, py = get_xy(float(i), number_radius)
        bw, bh = bmp.size
        img.paste(bmp, (int(px - bw / 2), int(py - bh / 2)), bmp)

    # Tick marks
    for i in range(96):
        hour_float = i / 4.0
        is_hour = (i % 4 == 0)
        ox, oy = get_xy(hour_float, tick_outer)
        if is_hour:
            ix, iy = get_xy(hour_float, hour_tick_inner)
            draw.line([(ox, oy), (ix, iy)], fill=(255, 255, 255), width=1)
        else:
            ix, iy = get_xy(hour_float, quarter_tick_inner)
            draw.line([(ox, oy), (ix, iy)], fill=(170, 170, 170), width=1)

    # Hour hand
    hour_float = hour + minute / 60.0
    angle_rad = math.radians((hour_float * 15.0) - 90.0)
    tip_radius = RADIUS - 26
    tail_length = 15
    arrow_head_length = 10
    arrow_half_width = 4

    tip_x = CENTER + tip_radius * math.cos(angle_rad)
    tip_y = CENTER + tip_radius * math.sin(angle_rad)
    tail_x = CENTER - tail_length * math.cos(angle_rad)
    tail_y = CENTER - tail_length * math.sin(angle_rad)
    shaft_end_r = tip_radius - arrow_head_length
    shaft_x = CENTER + shaft_end_r * math.cos(angle_rad)
    shaft_y = CENTER + shaft_end_r * math.sin(angle_rad)

    draw.line([(tail_x, tail_y), (shaft_x, shaft_y)], fill=(255, 255, 255), width=2)

    perp = angle_rad + math.pi / 2.0
    wlx = shaft_x + arrow_half_width * math.cos(perp)
    wly = shaft_y + arrow_half_width * math.sin(perp)
    wrx = shaft_x - arrow_half_width * math.cos(perp)
    wry = shaft_y - arrow_half_width * math.sin(perp)
    draw.polygon([(tip_x, tip_y), (wlx, wly), (wrx, wry)], fill=(255, 255, 255))

    # Minute hand
    if show_minute_hand:
        min_rad = math.radians((minute * 6.0) - 90.0)
        min_len = RADIUS - 50
        min_tail = 10
        mtx = CENTER + min_len * math.cos(min_rad)
        mty = CENTER + min_len * math.sin(min_rad)
        mtlx = CENTER - min_tail * math.cos(min_rad)
        mtly = CENTER - min_tail * math.sin(min_rad)
        draw.line([(mtlx, mtly), (mtx, mty)], fill=(170, 170, 170), width=2)

    # Center dot
    draw.ellipse([CENTER - 3, CENTER - 3, CENTER + 3, CENTER + 3], fill=(255, 255, 255))
    draw.ellipse([CENTER - 1, CENTER - 1, CENTER + 1, CENTER + 1], fill=(0, 0, 0))

    # Date
    if show_date:
        try:
            date_font = ImageFont.truetype(FONT_PATH, 14, index=0)
        except Exception:
            date_font = ImageFont.load_default()
        bbox = draw.textbbox((0, 0), date_str, font=date_font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        dx = CENTER - tw // 2
        dy = CENTER + 40
        draw.rectangle([dx - 3, dy - 1, dx + tw + 3, dy + th + 1], fill=(0, 0, 0))
        draw.text((dx, dy), date_str, font=date_font, fill=(170, 170, 170))

    return img


def main():
    scenes = [
        # (hour, minute, date, show_minute, show_date, filename, description)
        (10, 27, "Mar 27", True, True, "screen-image-1.png", "10:27 AM with date"),
        (16, 45, "Mar 27", True, True, "screen-image-2.png", "4:45 PM with date"),
        (22, 10, "Mar 27", False, True, "screen-image-3.png", "10:10 PM, no minute hand"),
    ]

    for hour, minute, date_str, show_min, show_date, filename, desc in scenes:
        img = render_watchface(hour, minute, date_str, show_min, show_date)

        out = os.path.join(SCRIPT_DIR, filename)
        img.save(out, optimize=True)
        size_kb = os.path.getsize(out) / 1024
        print(f"✅ {filename}: {desc} — {img.size[0]}x{img.size[1]}, {size_kb:.0f}KB")

        if size_kb > 150:
            print(f"   ⚠️ Over 150KB! Trying JPEG...")
            out_jpg = out.replace(".png", ".jpg")
            img.save(out_jpg, "JPEG", quality=85, optimize=True)
            print(f"   → {os.path.getsize(out_jpg)/1024:.0f}KB")

    # Clean up temp files
    for f in ["screen-260.png", "screen-520.png"]:
        p = os.path.join(SCRIPT_DIR, f)
        if os.path.exists(p):
            os.remove(p)

    print("\nDone!")


if __name__ == "__main__":
    main()
