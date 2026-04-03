#!/usr/bin/env python3
"""Generate pre-rotated number bitmaps for the 24-hour watch face dial.

Each number (24, 1-23) is rendered as white text on a transparent background,
rotated so it's oriented radially around the dial.

Numbers on the top half of the dial (18 through 6) are oriented so they read
from the outside inward (tops pointing toward center).
Numbers on the bottom half (7 through 17) are flipped 180° so they read
from the inside outward (readable from the bottom).

Requires: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

OUT_DIR = os.path.join(os.path.dirname(__file__), "resources", "drawables", "numbers")
FONT_SIZE = 13
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"
FONT_INDEX = 1  # Bold


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    font = ImageFont.truetype(FONT_PATH, FONT_SIZE, index=FONT_INDEX)
    labels = ["24"] + [str(i) for i in range(1, 24)]

    # Indices that should be flipped 180° (hours 7-17 → indices 7-17)
    flip_indices = set(range(7, 18))

    for i, label in enumerate(labels):
        # Each hour = 15 degrees clockwise from top
        angle_deg = i * 15.0

        # For hours 7-17, add 180° so text reads from the bottom
        if i in flip_indices:
            angle_deg += 180.0

        # Measure text
        bbox = font.getbbox(label)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]

        # Canvas large enough that rotation never clips
        size = int(math.sqrt(tw * tw + th * th)) + 8
        if size % 2 == 1:
            size += 1

        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        # Draw text centered on canvas
        x = (size - tw) / 2 - bbox[0]
        y = (size - th) / 2 - bbox[1]
        draw.text((x, y), label, font=font, fill=(255, 255, 255, 255))

        # Rotate clockwise (PIL rotates CCW, so negate)
        rotated = img.rotate(-angle_deg, resample=Image.BICUBIC, expand=False)

        # Crop to tight bounding box
        bbox_r = rotated.getbbox()
        if bbox_r:
            rotated = rotated.crop(bbox_r)

        out_path = os.path.join(OUT_DIR, f"num_{i:02d}.png")
        rotated.save(out_path)
        flipped = " (flipped)" if i in flip_indices else ""
        print(f"  {label:>2}: {rotated.size[0]:2d}x{rotated.size[1]:<2d} @ {angle_deg:5.1f}°{flipped}  -> {out_path}")

    print(f"\nGenerated {len(labels)} number images in {OUT_DIR}")


if __name__ == "__main__":
    main()
