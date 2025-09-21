import string
import unittest
import datetime as dt
import re
from textwrap import dedent
from .tool_driver import ToolDriver, InputEvent, TimeVal
from evdev import ecodes
from evdev.events import KeyEvent

EV_SYN: int = ecodes.EV_SYN  # type: ignore
EV_KEY: int = ecodes.EV_KEY  # type: ignore
SYN_REPORT: int = ecodes.SYN_REPORT  # type: ignore

SYN_EVENT = InputEvent(
    time=TimeVal(tv_sec=0, tv_usec=0),
    type=EV_SYN,
    code=SYN_REPORT,
    value=0,
)

CODE_BY_DESC: dict[str, int] = {
    "␣": ecodes.KEY_SPACE,  # type: ignore
    "LM": ecodes.KEY_LEFTMETA,  # type: ignore
    "LS": ecodes.KEY_LEFTSHIFT,  # type: ignore
    "ESC": ecodes.KEY_ESC,  # type: ignore
    "⎄": ecodes.KEY_PAUSE,  # type: ignore
    "mouse": ecodes.BTN_LEFT,  # type: ignore
    **{ch: getattr(ecodes, f"KEY_{ch}") for ch in string.ascii_uppercase},
}
DESC_BY_CODE = {code: desc for desc, code in CODE_BY_DESC.items()}

VALUE_BY_DIR = {
    "↓": KeyEvent.key_down,
    "⟳": KeyEvent.key_hold,
    "↑": KeyEvent.key_up,
}
DIR_BY_VALUE = {value: dir for dir, value in VALUE_BY_DIR.items()}


def parse_keypress(keypress: str, ts: dt.timedelta) -> InputEvent:
    key_desc = keypress[:-1]
    direction = keypress[-1]

    code = CODE_BY_DESC[key_desc]
    value = VALUE_BY_DIR[direction]
    assert ts.days == 0
    return InputEvent(
        time=TimeVal(tv_sec=ts.seconds, tv_usec=ts.microseconds),
        type=EV_KEY,
        code=code,
        value=value,
    )


def serialize_keypress(event: InputEvent) -> str:
    assert event.type == EV_KEY

    key_desc = DESC_BY_CODE[event.code]
    direction = DIR_BY_VALUE[event.value]
    return key_desc + direction


def format_ms(timedelta: dt.timedelta) -> str:
    return str(int(timedelta.total_seconds() * 1000)) + "ms"


def parse_ms(ts: str) -> dt.timedelta:
    assert ts.endswith("ms")
    return dt.timedelta(
        milliseconds=int(ts.removesuffix("ms")),
    )


def format_table(rows: list[list[str]]) -> str:
    """
    Formats the given data so columns align.
    """
    columns = list(zip(*rows))
    formatted_rows: list[str] = []

    for row in rows:
        formatted_row = []
        for i, col in enumerate(row):
            widest_value = max(columns[i], key=len)
            formatted_row.append(col.ljust(len(widest_value)))

        formatted_rows.append(" ".join(formatted_row))

    return "\n".join(formatted_rows)


class Timeline:
    def __init__(self):
        self.keyboard_events: list[InputEvent] = []
        self.computer_sees: list[list[InputEvent]] = []

    @classmethod
    def parse(cls, s: str):
        timeline = cls()

        lines = dedent(s).splitlines()
        prefixes = {"time: ", "keyboard: ", "computer sees: "}
        longest_prefix = max(*prefixes, key=len)
        line_by_prefix: dict[str, str] = {}
        for prefix in prefixes:
            (line,) = [line for line in lines if line.startswith(prefix)]
            line_by_prefix[prefix] = line[len(longest_prefix) :]

        keyboard_line = line_by_prefix["keyboard: "]
        computer_sees_line = line_by_prefix["computer sees: "]
        timestamps_line = line_by_prefix["time: "].ljust(len(max(lines, key=len)))
        for ts_match in re.finditer(r"\S+ *", timestamps_line):
            ts = parse_ms(ts_match.group().rstrip())

            # There should be exactly 1 keyboard event per timestamp.
            keyboard_snippet = keyboard_line[ts_match.start() : ts_match.end()]
            (keypress,) = keyboard_snippet.split()
            keyboard_event = parse_keypress(keypress, ts=ts)

            # There can be any number of "computer sees" events per timestamp,
            # however.
            computer_sees_snippet = computer_sees_line[
                ts_match.start() : ts_match.end()
            ]
            computer_sees_events = [
                parse_keypress(keypress, ts=ts)
                for keypress in computer_sees_snippet.split()
            ]

            timeline.add(
                keyboard=keyboard_event,
                computer_sees=computer_sees_events,
            )

        return timeline

    def add(self, keyboard: InputEvent, computer_sees: list[InputEvent]):
        assert keyboard.type == EV_KEY
        for event in computer_sees:
            assert event.type == EV_KEY

        self.keyboard_events.append(keyboard)
        self.computer_sees.append(computer_sees)

    def __str__(self) -> str:
        times = ["time: "] + [
            format_ms(e.time.as_timedelta()) for e in self.keyboard_events
        ]
        keyboard = ["keyboard: "] + [
            serialize_keypress(keypress) for keypress in self.keyboard_events
        ]
        computer_sees = ["computer sees: "] + [
            " ".join(serialize_keypress(event) for event in computer_see_events)
            for computer_see_events in self.computer_sees
        ]
        return format_table([times, keyboard, computer_sees])


class ToolBaseTest(unittest.TestCase):
    tool_cmd: list[str]

    def setUp(self):
        self.time_sec = 0
        self.driver = ToolDriver(command=self.tool_cmd)
        self.driver.start()
        self.addCleanup(self.driver.stop)

    def expect(self, timeline: str):
        expected_timeline = Timeline.parse(timeline)
        actual_timeline = Timeline()

        for event in expected_timeline.keyboard_events:
            self.driver.send_event(event)
            self.driver.send_event(SYN_EVENT)

            # Read as many resulting events as possible.
            resulting_events: list[InputEvent] = []
            while (
                computer_sees_event := self.driver.get_input_event(timeout_seconds=0.1)
            ) is not None:
                # skip SYN_REPORTS
                if computer_sees_event.type == SYN_EVENT.type:
                    continue

                resulting_events.append(computer_sees_event)

            actual_timeline.add(
                keyboard=event,
                computer_sees=resulting_events,
            )

        assert str(expected_timeline) == str(actual_timeline)
