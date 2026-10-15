#!/usr/bin/env python3
"""Measure how much of an emulator screencap frame is black - stdlib only.

`adb exec-out screencap` (no `-p`) writes a small header and then the pixels:
uint32 width, height, format, colorspace (little endian) followed by the rows
back to back. Format 1 is RGBA_8888 (4 bytes per pixel), which is what the
emulator's screencap produces; other formats are reported as unmeasurable
rather than guessed at.

Why this exists: `adb exec-out screencap -p` returns an all-black PNG when the
display has gone to sleep, and `ci/emulator_journey.sh` used to record only
adb's exit code for that capture. Run 38820683465 therefore published an
all-black `docs/screenshots/34_relaunch_real_app.png` - the one screenshot that
shows the app after a normal (non-test-harness) launch - while every phase key
said the run was fine. The frame is now measured instead of assumed, so a
screenshot that cannot show anything fails the run instead of passing quietly.

Usage:  screenshot_blankness.py <raw-frame-from-screencap>

Output: `<verdict>: <numbers> (<width>x<height> <format>)`, one line, where
verdict is `content`, `blank` or `unmeasurable`.

Exit status: 0 = the frame has content, 1 = the frame is (almost) all black,
2 = the frame cannot be judged (missing, truncated or unexpected format).
"""
import os
import struct
import sys

HEADER = 16                  # 4 uint32: width, height, format, colorspace
RGBA_8888 = 1                # 4 bytes per pixel, the emulator's default
BYTES_PER_PIXEL = {RGBA_8888: 4}
DARK = 8                     # a channel this dark or darker counts as black
BLANK_SHARE = 0.995          # this share of black pixels means "blank frame"
FORMAT_NAMES = {0: "rgb565", 1: "rgba8888", 2: "rgba_f16", 3: "rgbx_8888"}


def measure(path):
    """(verdict, description) for the raw frame at `path`."""
    try:
        size = os.path.getsize(path)
    except OSError as error:
        return "unmeasurable", "%s (%s)" % (error.strerror or error, path)
    with open(path, "rb") as handle:
        data = handle.read(HEADER)
        if len(data) < HEADER:
            return "unmeasurable", "only %d bytes, expected a %d-byte header" % (
                len(data), HEADER)
        width, height, pixel_format, _colorspace = struct.unpack("<IIII", data)
        per_pixel = BYTES_PER_PIXEL.get(pixel_format)
        name = FORMAT_NAMES.get(pixel_format, "format %d" % pixel_format)
        if per_pixel is None:
            return "unmeasurable", "pixel format %d (%s) is not RGBA_8888" % (
                pixel_format, name)
        if width == 0 or height == 0:
            return "unmeasurable", "header says %dx%d pixels" % (width, height)
        expected = width * height * per_pixel
        pixels = handle.read(expected)
    if len(pixels) < expected:
        return "unmeasurable", "%d of %d pixel bytes (%dx%d %s)" % (
            len(pixels), expected, width, height, name)
    black = 0
    for offset in range(0, expected, per_pixel):
        # Red, green and blue; a dark alpha channel must not hide content.
        if (pixels[offset] <= DARK and pixels[offset + 1] <= DARK
                and pixels[offset + 2] <= DARK):
            black += 1
    pixels_total = width * height
    share = black / pixels_total
    numbers = "%.1f%% of %d pixels are black (%dx%d %s, %d bytes)" % (
        share * 100.0, pixels_total, width, height, name, size)
    return ("blank" if share >= BLANK_SHARE else "content"), numbers


def main(argv):
    if len(argv) != 2:
        print("usage: %s <raw-frame-from-screencap>" % os.path.basename(argv[0]))
        return 2
    verdict, description = measure(argv[1])
    print("%s: %s" % (verdict, description))
    return {"content": 0, "blank": 1, "unmeasurable": 2}[verdict]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
