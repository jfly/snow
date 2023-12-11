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
            time:           0ms 50ms 200ms
            keyboard:       ␣↓  ␣⟳   ␣↑
            computer sees:  ⎄↓       ␣↓ ⎄↑ ␣↑
            """
        )

    def test_fast_double_tap_space_sends_space_repeat(self):
        self.expect(
            """
                                       This is <= 200ms
                  Keyrepeat ignored       |           Keyrepeat honored!
                                |         V             |
                                V      |---------|      V
            time:           0ms 250ms  300ms     500ms  550ms  500ms
            keyboard:       ␣↓  ␣⟳     ␣↑        ␣↓     ␣⟳     ␣↑
            computer sees:  ⎄↓         ␣↓ ⎄↑ ␣↑  ␣↓     ␣⟳     ␣↑
            """
        )

    def test_slow_double_tap_space_does_not_repeat(self):
        self.expect(
            """
                                  This is more than 200ms
                                    |
                                    V
                                 |---------|
            time:           0ms  100ms     301ms  350ms  400ms
            keyboard:       ␣↓   ␣↑        ␣↓     ␣⟳     ␣↑
            computer sees:  ⎄↓   ␣↓ ⎄↑ ␣↑  ⎄↓            ␣↓ ⎄↑ ␣↑

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

    def test_mouse_click_chords_on_key_down(self):
        """
        Unlike key presses, we want mouse clicks to chord on key down, rather
        than key release.
        """
        self.expect(
            """
            time:           0ms 50ms           100ms 150ms
            keyboard:       ␣↓  mouse↓         mouse↑   ␣↑
            computer sees:  ⎄↓  LM↓ ⎄↑ mouse↓  mouse↑   LM↑
            """
        )

    def test_mouse_click_with_buffered_key_chords_on_key_down(self):
        """
        This is similar to `test_mouse_click_chords_on_key_down`, except with a
        buffered key this time.
        """
        self.expect(
            """
            time:           0ms 50ms  100ms              150ms    200ms   250ms
            keyboard:       ␣↓  A↓    mouse↓             mouse↑   ␣↑      A↑
            computer sees:  ⎄↓        LM↓ ⎄↑ A↓ mouse↓   mouse↑   LM↑     A↑
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

    def test_can_chord_if_shift_is_down(self):
        """
        I sometimes type commands like MOD + SHIFT + G with SHIFT + SPACE + G.
        We should treat SHIFT specially so it being held doesn't prevent SPACE
        from getting treated as MOD.
        """
        self.expect(
            """
            time:           0ms 50ms 100ms 150ms         150ms 200ms
            keyboard:       LS↓ ␣↓   G↓    G↑            LS↑   ␣↑
            computer sees:  LS↓ ⎄↓         LM↓ ⎄↑ G↓ G↑  LS↑   LM↑
            """
        )
