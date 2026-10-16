#!/usr/bin/env python3
"""Measure a captured screen frame - stdlib only, so it can run on the runner.

Two input shapes are understood:

* a PNG, which is what `adb exec-out screencap -p` produces and therefore the
  file that gets published as evidence (`docs/screenshots/...`). Decoding it
  here means the published file is judged by its own pixels instead of by a
  second, separate capture that can disagree with it.
* a raw frame (`adb exec-out screencap` without -p): a 16-byte header (uint32
  width, height, format, colorspace, little endian) followed by the rows back to
  back. Only RGBA_8888 (format 1) is accepted; anything else is reported as
  unmeasurable rather than guessed at.

Why this exists: the relaunch screenshot - the one screenshot that has to show
the app after a normal (non-test-harness) launch - came out as an all-black
frame in run 38820683465 while adb exited 0, and in run 38824894610 the frame
measured right after it was black while the published PNG held a real main map.
A frame nobody measures can be published as if it proved something; now the
capture that is published is the capture that is measured.

Output: one line, `<verdict>: <numbers> (<width>x<height> <format>)`, where the
verdict is `content`, `blank` or `unmeasurable`. A blank frame also reports the
bounding box of its few bright pixels, which is what tells a platform splash
window or a status bar apart from an app that has painted.

Exit status: 0 = the frame has content, 1 = the frame is (almost) all black,
2 = the frame cannot be judged (missing, truncated, unreadable or a format this
tool does not decode).

Usage: screenshot_blankness.py <frame.png|frame.raw>
"""
import struct
import sys
import zlib

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
RAW_HEADER = 16              # 4 uint32: width, height, format, colorspace
RGBA_8888 = 1                # 4 bytes per pixel, the emulator's default
DARK = 8                     # a channel this dark or darker counts as black
BLANK_SHARE = 0.95           # this share of black pixels means "blank frame"

# The threshold separates "the app painted" from "it did not". PyQuest paints its
# screens on sky-blue and parchment (the main map is ~90% non-black), while the
# platform's starting window and an unpainted surface come back 100% black or
# black with just an icon or a status bar (>=99% black). A frame at or above 95%
# black is therefore no evidence that the app drew, and ci/emulator_journey.sh
# captures again instead of publishing it.

RAW_FORMAT_NAMES = {0: "rgb565", 1: "rgba8888", 2: "rgba_f16", 3: "rgbx_8888"}
PNG_CHANNELS = {0: 1, 2: 3, 4: 2, 6: 4}          # grey, rgb, grey+alpha, rgba
PNG_COLOUR_NAMES = {0: "grey", 2: "rgb", 3: "palette", 4: "grey+alpha",
                    6: "rgba"}


def _fail(reason):
    return None, reason


def read_png(data):
    """(frame, error) - decoded 8-bit rows of a PNG, as RGB triplets."""
    position = len(PNG_SIGNATURE)
    chunks = bytearray()
    header = None
    while position + 8 <= len(data):
        length = int.from_bytes(data[position:position + 4], "big")
        tag = data[position + 4:position + 8]
        payload = data[position + 8:position + 8 + length]
        if len(payload) < length:
            return _fail("PNG ends inside the %s chunk" % tag.decode("latin-1"))
        if tag == b"IHDR":
            header = payload
        elif tag == b"IDAT":
            chunks += payload
        elif tag == b"IEND":
            break
        position += 12 + length
    if header is None or not chunks:
        return _fail("PNG has no %s" % ("header" if header is None else "pixels"))
    width, height, depth, colour, compression, filtering, interlace = \
        struct.unpack(">IIBBBBB", header)
    channels = PNG_CHANNELS.get(colour)
    if channels is None:
        return _fail("PNG colour type %d (%s) is not decoded here"
                     % (colour, PNG_COLOUR_NAMES.get(colour, "?")))
    if depth != 8:
        return _fail("PNG is %d bits per channel, expected 8" % depth)
    if interlace != 0:
        return _fail("PNG is interlaced")
    if compression != 0 or filtering != 0:
        return _fail("PNG uses unsupported compression/filter method")
    if width == 0 or height == 0:
        return _fail("PNG says %dx%d pixels" % (width, height))
    try:
        rows = zlib.decompress(bytes(chunks))
    except zlib.error as error:
        return _fail("PNG pixels do not decompress (%s)" % error)
    try:
        unfiltered = _unfilter(rows, width, height, channels)
    except ValueError as error:
        return _fail(str(error))
    return {"width": width, "height": height, "bytes": len(data),
            "name": "png %s" % PNG_COLOUR_NAMES.get(colour, "?"),
            "pixels": _to_rgb(unfiltered, channels)}, None


def _unfilter(rows, width, height, channels):
    """PNG filter reconstruction (types 0-4), returning RGB-agnostic bytes."""
    stride = width * channels
    previous = bytearray(stride)
    output = bytearray()
    position = 0
    for row_number in range(height):
        if position >= len(rows):
            raise ValueError("PNG holds %d of %d rows" % (row_number, height))
        filter_type = rows[position]
        position += 1
        row = bytearray(rows[position:position + stride])
        if len(row) < stride:
            raise ValueError("PNG row %d is short (%d of %d bytes)"
                             % (row_number, len(row), stride))
        position += stride
        if filter_type == 1:
            for index in range(channels, stride):
                row[index] = (row[index] + row[index - channels]) & 0xFF
        elif filter_type == 2:
            for index in range(stride):
                row[index] = (row[index] + previous[index]) & 0xFF
        elif filter_type == 3:
            for index in range(stride):
                left = row[index - channels] if index >= channels else 0
                row[index] = (row[index] + ((left + previous[index]) >> 1)) & 0xFF
        elif filter_type == 4:
            for index in range(stride):
                left = row[index - channels] if index >= channels else 0
                up = previous[index]
                corner = previous[index - channels] if index >= channels else 0
                estimate = left + up - corner
                distances = (abs(estimate - left), abs(estimate - up),
                             abs(estimate - corner))
                if distances[0] <= distances[1] and distances[0] <= distances[2]:
                    prediction = left
                elif distances[1] <= distances[2]:
                    prediction = up
                else:
                    prediction = corner
                row[index] = (row[index] + prediction) & 0xFF
        elif filter_type != 0:
            raise ValueError("PNG row %d uses filter type %d"
                             % (row_number, filter_type))
        output += row
        previous = row
    return output


def _to_rgb(pixels, channels):
    """Flatten whatever the PNG held into RGB triplets."""
    if channels == 3:
        return bytes(pixels)
    output = bytearray()
    for start in range(0, len(pixels), channels):
        if channels == 1 or channels == 2:       # grey, grey+alpha
            output += bytes((pixels[start],)) * 3
        else:                                     # rgba: drop alpha
            output += pixels[start:start + 3]
    return bytes(output)


def read_raw(data):
    """(frame, error) - decoded rows of a raw `screencap` frame."""
    if len(data) < RAW_HEADER:
        return _fail("only %d bytes, expected a %d-byte header"
                     % (len(data), RAW_HEADER))
    width, height, pixel_format, _colorspace = struct.unpack("<IIII",
                                                             data[:RAW_HEADER])
    if pixel_format != RGBA_8888:
        return _fail("pixel format %d (%s) is not RGBA_8888"
                     % (pixel_format, RAW_FORMAT_NAMES.get(pixel_format, "?")))
    if width == 0 or height == 0:
        return _fail("header says %dx%d pixels" % (width, height))
    expected = width * height * 4
    pixels = data[RAW_HEADER:RAW_HEADER + expected]
    if len(pixels) < expected:
        return _fail("%d of %d pixel bytes (%dx%d rgba8888)"
                     % (len(pixels), expected, width, height))
    return {"width": width, "height": height, "bytes": len(data),
            "name": "rgba8888", "pixels": _to_rgb(pixels, 4)}, None


def read_frame(path):
    """(frame, error) for a PNG or a raw screencap frame."""
    try:
        with open(path, "rb") as handle:
            data = handle.read()
    except OSError as error:
        return _fail("%s (%s)" % (error.strerror or error, path))
    if len(data) < RAW_HEADER:
        return _fail("%s holds only %d bytes" % (path, len(data)))
    if data.startswith(PNG_SIGNATURE):
        return read_png(data)
    return read_raw(data)


def measure(frame):
    """(verdict, description) - how much of the frame is black."""
    width, height, pixels = frame["width"], frame["height"], frame["pixels"]
    black = 0
    left = top = None
    right = bottom = 0
    for index in range(0, len(pixels), 3):
        if (pixels[index] <= DARK and pixels[index + 1] <= DARK
                and pixels[index + 2] <= DARK):
            black += 1
            continue
        pixel = index // 3
        x, y = pixel % width, pixel // width
        if left is None or x < left:
            left = x
        if x > right:
            right = x
        if top is None or y < top:
            top = y
        if y > bottom:
            bottom = y
    total = width * height
    share = black / total
    numbers = "%.1f%% of %d pixels are black (%dx%d %s, %d bytes)" % (
        share * 100.0, total, width, height, frame["name"], frame["bytes"])
    if share >= BLANK_SHARE:
        if left is None:
            numbers += "; nothing at all was drawn"
        else:
            numbers += ("; the only bright pixels are in %dx%d at (%d,%d)"
                        % (right - left + 1, bottom - top + 1, left, top))
        return "blank", numbers
    return "content", numbers


def main(argv):
    if len(argv) != 2:
        print(__doc__.strip().splitlines()[-1])
        return 2
    frame, error = read_frame(argv[1])
    if frame is None:
        print("unmeasurable: %s" % error)
        return 2
    verdict, numbers = measure(frame)
    print("%s: %s" % (verdict, numbers))
    return {"content": 0, "blank": 1}[verdict]


if __name__ == "__main__":
    sys.exit(main(sys.argv))
