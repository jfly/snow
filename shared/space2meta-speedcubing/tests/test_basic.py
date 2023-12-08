from .testing import ToolBaseTest


class TestSpace2MetaFancy(ToolBaseTest):
    tool_cmd = ["space2meta-speedcubing"]

    def test_tap_a(self):
        self.expect(
            """
            time:          0ms     50ms
            keyboard:      A↓      A↑
            computer sees: A↓      A↑
            """
        )

    def test_tap_space(self):
        self.expect(
            """
            time:           0ms 50ms 199ms
            keyboard:       ␣↓  ␣⟳   ␣↑
            computer sees:  ⎄↓       ␣↓ ⎄↑ ␣↑
            """
        )

    def test_hold_space(self):
        self.expect(
            """
            time:           0ms     200ms    250ms
            keyboard:       ␣↓      ␣⟳       ␣↑
            computer sees:  ⎄↓      ␣↓ ⎄↑    ␣↑
            """
        )

    def test_hold_space_multi(self):
        self.expect(
            """
            time:           0ms     200ms    250ms  300ms  500ms  550ms
            keyboard:       ␣↓      ␣⟳       ␣↑     ␣↓     ␣⟳     ␣↑
            computer sees:  ⎄↓      ␣↓ ⎄↑    ␣↑     ⎄↓     ␣↓ ⎄↑  ␣↑
            """
        )

    def test_no_chord_on_key_down(self):
        self.expect(
            """
            time:           0ms  50ms    100ms        150ms
            keyboard:       ␣↓   A↓      ␣↑           A↑
            computer sees:  ⎄↓           ␣↓ ⎄↑ ␣↑ A↓  A↑
            """
        )

    def test_chord_on_key_up(self):
        self.expect(
            """
            time:           0ms  50ms 100ms         150ms
            keyboard:       ␣↓   A↓   A↑            ␣↑
            computer sees:  ⎄↓        LM↓ ⎄↑ A↓ A↑  LM↑
            """
        )

    def test_slow_no_chord_on_key_down(self):
        self.expect(
            """
            time:           0ms  200ms  250ms  400ms  350ms
            keyboard:       ␣↓   ␣⟳     A↓     ␣↑     A↑
            computer sees:  ⎄↓   ␣↓ ⎄↑         A↓ ␣↑  A↑
                                                  ^
                                                  |
                                    Note that we intentionally wait to release
                                    the space until *after* sending the
                                    buffered keypress. This allows us to switch
                                    from holding space to holding another key
                                    without starting a Rubik's cube timer.
            """
        )

    def test_slow_chord_on_key_up(self):
        self.expect(
            """
            time:           0ms  200ms  250ms  350ms         400ms
            keyboard:       ␣↓   ␣⟳     A↓     A↑            ␣↑
            computer sees:  ⎄↓   ␣↓ ⎄↑         LM↓ A↓ A↑ ␣↑  LM↑
                                                         ^
                                                         |
                                    Note that we intentionally wait to release
                                    the space until *after* the meta chord.
                                    This lets us navigate away from a Rubik's
                                    cube timer without starting it (the window
                                    loses focus and then doesn't receive the
                                    space key release event)
            """
        )

    def test_multi_chord(self):
        self.expect(
            """
            time:           0ms  200ms 250ms          300ms  350ms  375ms
            keyboard:       ␣↓   A↓    A↑             B↓     B↑     ␣↑
            computer sees:  ⎄↓         LM↓ ⎄↑ A↓ A↑   B↓     B↑     LM↑
            """
        )

    def test_esc_resets(self):
        # Escape should not chord with space, it should just reset things.
        # Note that this does result in a phantom space release getting
        # emitted. While we could get fancy to try to suppress that, it would
        # require more state and thereby defeat the whole purpose of escape
        # being a simple reset mechanism.
        self.expect(
            """
            time:           0ms  50ms     100ms  150ms
            keyboard:       ␣↓   ESC↓     ESC↑   ␣↑
            computer sees:  ⎄↓   ESC↓ ⎄↑  ESC↑   ␣↑
            """
        )

    def test_no_chording_if_keys_are_down(self):
        """
        Here's real recording of me typing "s t", note how the T gets pressed
        while space is held. We don't want this to result in a chorded meta,
        though.
        """
        self.expect(
            """
            time:           0ms 50ms 100ms 150ms 200ms 250ms
            keyboard:       S↓  ␣↓   T↓    S↑    ␣↑    T↑
            computer sees:  S↓  ␣↓   T↓    S↑    ␣↑    T↑
            """
        )

    def test_real_typing(self):
        """
        Here's a real recording of me typing "are you" as fast as I can, with
        all the interleaved messiness. Basically, I seem to rely upon key down
        resulting in the character getting typed, and it might take a few
        characters before I actually release keys.
        """
        self.expect(
            """
            time:           0ms 50ms 100ms 150ms 200ms 250ms 300ms 350ms 400ms 450ms 500ms 550ms 600ms 650ms
            keyboard:       A↓  R↓   E↓    A↑    ␣↓    R↑    Y↓    ␣↑    E↑    O↓    Y↑    U↓    O↑    U↑
            computer sees:  A↓  R↓   E↓    A↑    ␣↓    R↑    Y↓    ␣↑    E↑    O↓    Y↑    U↓    O↑    U↑
            """
        )
