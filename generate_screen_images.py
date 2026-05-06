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

# Mirror highlightColor() in TwentyFourHourView.mc
HIGHLIGHT_COLORS = {
    1: (255, 255, 0),      # Yellow
    2: (255, 0, 0),        # Red
    3: (0, 255, 0),        # Green
    4: (0, 0, 255),        # Blue
    5: (255, 170, 0),      # Orange (Garmin COLOR_ORANGE = 0xFFAA00)
}


def get_xy(hour_float, r, noon_at_top=False):
    angle_deg = (hour_float * 15.0) - 90.0
    if noon_at_top:
        angle_deg += 180.0
    angle_rad = math.radians(angle_deg)
    x = CENTER + r * math.cos(angle_rad)
    y = CENTER + r * math.sin(angle_rad)
    return x, y


def render_watchface(
    hour,
    minute,
    date_str,
    show_minute_hand=True,
    show_date=True,
    noon_at_top=False,
    five_min_color=0,
    show_battery=False,
    battery_pct=100,
):
    img = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    draw = ImageDraw.Draw(img)

    prefix = "num_noon_" if noon_at_top else "num_"
    num_images = [
        Image.open(os.path.join(NUM_DIR, f"{prefix}{i:02d}.png")).convert("RGBA")
        for i in range(24)
    ]

    number_radius = RADIUS - 8
    tick_outer = RADIUS - 18
    hour_tick_inner = RADIUS - 32
    quarter_tick_inner = RADIUS - 25

    for i in range(24):
        bmp = num_images[i]
        px, py = get_xy(float(i), number_radius, noon_at_top)
        bw, bh = bmp.size
        img.paste(bmp, (int(px - bw / 2), int(py - bh / 2)), bmp)

    highlight_on = five_min_color > 0
    highlight_rgb = HIGHLIGHT_COLORS.get(five_min_color, (255, 255, 255))

    for i in range(96):
        hour_float = i / 4.0
        is_hour = (i % 4 == 0)
        is_five_min = (i % 8 == 0)
        ox, oy = get_xy(hour_float, tick_outer, noon_at_top)
        if is_hour:
            ix, iy = get_xy(hour_float, hour_tick_inner, noon_at_top)
            color = highlight_rgb if (highlight_on and is_five_min) else (255, 255, 255)
            draw.line([(ox, oy), (ix, iy)], fill=color, width=1)
        else:
            ix, iy = get_xy(hour_float, quarter_tick_inner, noon_at_top)
            draw.line([(ox, oy), (ix, iy)], fill=(170, 170, 170), width=1)

    # Hour hand
    hour_float = hour + minute / 60.0
    angle_deg = (hour_float * 15.0) - 90.0
    if noon_at_top:
        angle_deg += 180.0
    angle_rad = math.radians(angle_deg)
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

    if show_minute_hand:
        min_rad = math.radians((minute * 6.0) - 90.0)
        min_len = RADIUS - 50
        min_tail = 10
        mtx = CENTER + min_len * math.cos(min_rad)
        mty = CENTER + min_len * math.sin(min_rad)
        mtlx = CENTER - min_tail * math.cos(min_rad)
        mtly = CENTER - min_tail * math.sin(min_rad)
        min_color = highlight_rgb if highlight_on else (170, 170, 170)
        draw.line([(mtlx, mtly), (mtx, mty)], fill=min_color, width=2)

    draw.ellipse([CENTER - 3, CENTER - 3, CENTER + 3, CENTER + 3], fill=(255, 255, 255))
    draw.ellipse([CENTER - 1, CENTER - 1, CENTER + 1, CENTER + 1], fill=(0, 0, 0))

    try:
        text_font = ImageFont.truetype(FONT_PATH, 14, index=0)
    except Exception:
        text_font = ImageFont.load_default()

    if show_date:
        bbox = draw.textbbox((0, 0), date_str, font=text_font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        dx = CENTER - tw // 2
        dy = CENTER + 40
        draw.rectangle([dx - 3, dy - 1, dx + tw + 3, dy + th + 1], fill=(0, 0, 0))
        draw.text((dx, dy), date_str, font=text_font, fill=(170, 170, 170))

    if show_battery:
        batt_str = f"{battery_pct}%"
        bbox = draw.textbbox((0, 0), batt_str, font=text_font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        bx = CENTER - tw // 2
        by = CENTER - 40 - th
        draw.rectangle([bx - 3, by - 1, bx + tw + 3, by + th + 1], fill=(0, 0, 0))
        if battery_pct <= 10:
            batt_color = (255, 0, 0)
        elif battery_pct <= 25:
            batt_color = (255, 255, 0)
        else:
            batt_color = (170, 170, 170)
        draw.text((bx, by), batt_str, font=text_font, fill=batt_color)

    return img


def main():
    scenes = [
        # Showcase the original look (defaults — backward compatible)
        dict(
            hour=10, minute=27, date_str="Mar 27",
            show_minute_hand=True, show_date=True,
            filename="screen-image-1.png",
            description="10:27 AM — classic 24h dial",
        ),
        # Showcase v2: noon-at-top + orange highlights + battery + colored minute hand
        dict(
            hour=16, minute=45, date_str="Mar 27",
            show_minute_hand=True, show_date=True,
            noon_at_top=True, five_min_color=5,
            show_battery=True, battery_pct=68,
            filename="screen-image-2.png",
            description="4:45 PM — noon at top, orange tick highlights, battery",
        ),
        # Night, hour-hand only, with date and low-battery indicator
        dict(
            hour=22, minute=10, date_str="Mar 27",
            show_minute_hand=False, show_date=True,
            show_battery=True, battery_pct=18,
            filename="screen-image-3.png",
            description="10:10 PM — minimalist, low-battery indicator",
        ),
    ]

    for scene in scenes:
        filename = scene.pop("filename")
        description = scene.pop("description")
        img = render_watchface(**scene)

        out = os.path.join(SCRIPT_DIR, filename)
        img.save(out, optimize=True)
        size_kb = os.path.getsize(out) / 1024
        print(f"✅ {filename}: {description} — {img.size[0]}x{img.size[1]}, {size_kb:.0f}KB")

        if size_kb > 150:
            print(f"   ⚠️ Over 150KB! Saving as JPEG...")
            out_jpg = out.replace(".png", ".jpg")
            img.save(out_jpg, "JPEG", quality=85, optimize=True)
            print(f"   → {os.path.getsize(out_jpg)/1024:.0f}KB")

    print("\nDone!")


if __name__ == "__main__":
    main()
