#!/usr/bin/env python

from own_clipboard import own_clipboard, not_too_often
import urwid
import threading
import os
import argparse


def main():
    parser = argparse.ArgumentParser(
        description="Add each line in a file to the clipboard, one by one"
    )
    parser.add_argument("file", type=argparse.FileType(mode="r", encoding="utf-8"))
    args = parser.parse_args()

    choices = [l.strip() for l in args.file.readlines()]

    body = [urwid.Text("Clipboard"), urwid.Divider()]
    for c in choices:
        button = urwid.Button(c)
        body.append(urwid.AttrMap(button, None, focus_map="reversed"))

    list_walker = urwid.SimpleFocusListWalker(body)
    menu = urwid.ListBox(list_walker)

    top = urwid.Overlay(
        menu,
        urwid.SolidFill("\N{MEDIUM SHADE}"),
        align="center",
        width=("relative", 100),
        valign="middle",
        height=("relative", 100),
        min_width=20,
        min_height=9,
    )
    main_loop = urwid.MainLoop(
        top, palette=[("reversed", "standout", "")], handle_mouse=False
    )

    def next_item(data):
        if data == b"next":
            try:
                next_pos = list_walker.next_position(list_walker.focus)
            except IndexError:
                next_pos = list_walker.focus
            list_walker.focus = next_pos
            list_walker._modified()
        else:
            assert False, f"I don't know what to do with {data!r}"

    next_fd = main_loop.watch_pipe(next_item)

    @not_too_often
    def generator() -> bytes:
        focus = list_walker.get_focus()[0]
        assert focus
        choice = focus.original_widget.get_label()
        os.write(next_fd, b"next")
        return choice.encode("utf-8")

    t = threading.Thread(target=lambda: own_clipboard(generator), daemon=True)
    t.start()

    main_loop.run()


if __name__ == "__main__":
    main()
