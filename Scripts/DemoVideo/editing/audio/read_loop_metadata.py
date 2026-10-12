"""Prints the tempo, key and descriptors stored in Apple Loops .caf files, to pick loops that play together.

Usage: read_loop_metadata.py <file-or-folder> ...
"""
import struct
import sys
from pathlib import Path


def chunks(path):
    data = path.read_bytes()
    offset = 8  # 'caff' header: type, version, flags
    while offset + 12 <= len(data):
        kind = data[offset:offset + 4].decode("latin-1")
        (size,) = struct.unpack(">q", data[offset + 4:offset + 12])
        body = data[offset + 12:offset + 12 + size] if size >= 0 else data[offset + 12:]
        yield kind, body
        if size < 0:
            break
        offset += 12 + size


def metadata(path):
    found = {}
    for kind, body in chunks(path):
        if kind == "info":
            # A count, then NUL-terminated key and value strings.
            strings = body[4:].split(b"\0")
            found.update({strings[i].decode("utf-8", "replace"): strings[i + 1].decode("utf-8", "replace")
                          for i in range(0, len(strings) - 1, 2) if strings[i]})
        elif kind == "uuid":
            # Apple's loop chunk: a 16-byte id, then the same count and string pairs.
            strings = body[20:].split(b"\0")
            found.update({strings[i].decode("utf-8", "replace"): strings[i + 1].decode("utf-8", "replace")
                          for i in range(0, len(strings) - 1, 2) if strings[i] and strings[i].isascii()})
    return found


if __name__ == "__main__":
    for argument in sys.argv[1:]:
        argument = Path(argument)
        for path in sorted(argument.glob("*.caf")) if argument.is_dir() else [argument]:
            values = metadata(path)
            print(f"{path.stem:34} " + "  ".join(f"{key}={value}" for key, value in values.items()
                                                  if key in ("tempo", "key signature", "time signature", "root key",
                                                             "scale type", "category", "subcategory", "genre",
                                                             "descriptors", "beat count")))
