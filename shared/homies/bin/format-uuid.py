#!/usr/bin/env python

import ast
import sys
import uuid


def try_parse_bytes(s):
    try:
        bs = ast.literal_eval(clip)
    except (SyntaxError, ValueError):
        return None
    try:
        return uuid.UUID(bytes=bs)
    except ValueError:
        return None
    except TypeError:
        return None


def try_parse_hex(s):
    s = s.replace("0x", "")
    try:
        s = ast.literal_eval(s)
    except (SyntaxError, ValueError):
        pass

    try:
        return uuid.UUID(hex=s)
    except ValueError:
        return None


clip = sys.stdin.read().strip()
parsed = try_parse_bytes(clip)
if parsed is None:
    parsed = try_parse_hex(clip)

if parsed is None:
    print(f"This doesn't look like a hex or a bytes based uuid: {clip}")
    sys.exit(1)

pretty = str(parsed)
formats = [
    pretty,
    pretty.replace("-", ""),
    pretty.upper(),
    pretty.upper().replace("-", ""),
    repr(parsed.bytes),
    "0x" + pretty.upper().replace("-", ""),
]

print("\n".join(formats))
