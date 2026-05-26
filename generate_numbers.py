#!/usr/bin/env python3
"""Generate pre-rotated number bitmaps for the 24-hour watch face dial.

Three sets are produced:
  - Standard set (numbers/num_NN.png): rotated, hour 0/24 at top of dial.
  - Noon-at-top set (numbers/num_noon_NN.png): rotated, hour 12 at top.
  - Upright set (numbers/num_up_NN.png): no rotation, used for both
    orientations (the slot position differs, the bitmap doesn't).

In the rotated sets, numbers on the upper half of the dial read normally;
numbers on the lower half are flipped 180° so they're readable from the
bottom. In the upright set, all numbers read normally.

Requires: pip3 install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

OUT_DIR = os.path.join(os.path.dirname(__file__), "resources", "drawables", "numbers")
FONT_SIZE = 13
FONT_PATH = "/System/Library/Fonts/Helvetica.ttc"
FONT_INDEX = 1  # Bold


def render(label, angle_deg, flip):
    if flip:
        angle_deg += 180.0

    bbox = font.getbbox(label)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]

    size = int(math.sqrt(tw * tw + th * th)) + 8
    if size % 2 == 1:
        size += 1

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1]
    draw.text((x, y), label, font=font, fill=(255, 255, 255, 255))

    rotated = img.rotate(-angle_deg, resample=Image.BICUBIC, expand=False)
    bbox_r = rotated.getbbox()
    if bbox_r:
        rotated = rotated.crop(bbox_r)
    return rotated


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    global font
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE, index=FONT_INDEX)

    labels = ["24"] + [str(i) for i in range(1, 24)]

    # Standard set: hour 0 at top. Hours 7..17 are on the bottom half.
    std_flip = set(range(7, 18))
    # Noon-at-top set: hour 12 at top. Bottom half is hours 19..23 and 0..5.
    noon_flip = set(range(19, 24)) | set(range(0, 6))

    for i, label in enumerate(labels):
        # Standard
        angle_std = i * 15.0
        img_std = render(label, angle_std, i in std_flip)
        path_std = os.path.join(OUT_DIR, f"num_{i:02d}.png")
        img_std.save(path_std)

        # Noon-at-top: hour i sits at angle (i-12)*15° from top
        angle_noon = (i - 12) * 15.0
        img_noon = render(label, angle_noon, i in noon_flip)
        path_noon = os.path.join(OUT_DIR, f"num_noon_{i:02d}.png")
        img_noon.save(path_noon)

        # Upright: no rotation, no flip. Same bitmap for both orientations.
        img_up = render(label, 0.0, False)
        path_up = os.path.join(OUT_DIR, f"num_up_{i:02d}.png")
        img_up.save(path_up)

    print(f"\nGenerated {len(labels) * 3} number images in {OUT_DIR}")


if __name__ == "__main__":
    main()
