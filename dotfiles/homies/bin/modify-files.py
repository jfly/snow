#!/usr/bin/env python3

import fileinput
import re
import sys

PATTERN = r"types\.([A-Z].*)Condition"
def repl(match):
    s = f"types.conditions.{match.group(1)}"
    print(f"{match.group(0)} ----------> {s}", file=sys.stderr)
    return s

def CamelCase(snake_str):
    return ''.join(map(str.title, snake_str.split('_')))

def main():
    with fileinput.input(inplace=True) as f:
        for line in f:
            print(re.sub(PATTERN, repl, line), end="")

if __name__ == "__main__":
    main()
