#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include <linux/input.h>
#include <unistd.h>

#define DUR_MILLIS(start, end)                                                 \
  ((end.tv_sec - start.tv_sec) * 1000 + (end.tv_usec - start.tv_usec) / 1000)

/* https://www.kernel.org/doc/html/latest/input/event-codes.html */
#define INPUT_VAL_PRESS 1
#define INPUT_VAL_REPEAT 2
#define INPUT_VAL_RELEASE 0

// clang-format off
const struct input_event
syn          = {.type = EV_SYN , .code = SYN_REPORT   , .value = 0},
space_down   = {.type = EV_KEY , .code = KEY_SPACE    , .value = 1},
space_up     = {.type = EV_KEY , .code = KEY_SPACE    , .value = 0},
noop_down    = {.type = EV_KEY , .code = KEY_PAUSE    , .value = 1},
noop_up      = {.type = EV_KEY , .code = KEY_PAUSE    , .value = 0},
meta_down    = {.type = EV_KEY , .code = KEY_LEFTMETA , .value = 1},
meta_up      = {.type = EV_KEY , .code = KEY_LEFTMETA , .value = 0};
// clang-format on

int read_event(struct input_event *event) {
  return fread(event, sizeof(struct input_event), 1, stdin) == 1;
}

void write_event(const struct input_event *event) {
  if (fwrite(event, sizeof(struct input_event), 1, stdout) != 1) {
    exit(EXIT_FAILURE);
  }
}

#define DELAY 20000
void write_events(int event_count, ...) {
  va_list args;
  va_start(args, event_count);

  bool has_emitted_event = false;
  for (int i = 0; i < event_count; ++i) {
    const struct input_event *event = va_arg(args, const struct input_event *);
    if (event) {
      if (i > 0 && has_emitted_event) {
        // SYN and DELAY are necessary for "correct synthesization of event
        // sequences"
        // https://gitlab.com/interception/linux/tools#correct-synthesization-of-event-sequences
        write_event(&syn);
        usleep(DELAY);
      }
      write_event(event);
      has_emitted_event = true;
    }
  }

  va_end(args);
}

#define WRITE_EVENTS2(e1, e2) write_events(2, e1, e2)
#define WRITE_EVENTS3(e1, e2, e3) write_events(3, e1, e2, e3)
#define WRITE_EVENTS4(e1, e2, e3, e4) write_events(4, e1, e2, e3, e4)

#define GET_WRITE_EVENTS(_1, _2, _3, _4, NAME, ...) NAME
#define WRITE_EVENTS(...)                                                      \
  GET_WRITE_EVENTS(__VA_ARGS__, WRITE_EVENTS4, WRITE_EVENTS3, WRITE_EVENTS2)   \
  (__VA_ARGS__)

int main(__attribute__((unused)) int argc,
         __attribute__((unused)) char *argv[]) {
  setbuf(stdin, NULL);
  setbuf(stdout, NULL);

  enum {
    START,
    SPACE_HELD,
    SPACE_IS_SPACE,
    SPACE_IS_REALLY_SPACE,
    SPACE_IS_META
  } state = START;
  struct timeval space_held_start;

  int keys_held_count = 0;

  bool is_key_buffered = 0;
  struct input_event buffered_key_event;

  struct input_event event;
  while (read_event(&event)) {
    // Forward anything that is not a key event, including SYNs.
    if (event.type != EV_KEY) {
      write_event(&event);
      continue;
    }

    // Bookkeeping of how many keys are currently held down.
    if (event.value == INPUT_VAL_PRESS) {
      keys_held_count++;
    } else if (event.value == INPUT_VAL_RELEASE) {
      // Just in case we somehow screwed up the bookkeping, don't let the key
      // count drop negative.
      if (keys_held_count > 0) {
        keys_held_count--;
      }
    }

    if (event.code == KEY_SPACE && event.value == INPUT_VAL_PRESS) {
      if (state == START) {
        if (keys_held_count == 1) {
          write_event(&noop_down);
          state = SPACE_HELD;
          space_held_start = event.time;
          continue;
        } else {
          write_event(&event);
          state = SPACE_IS_REALLY_SPACE;
          continue;
        }
      }
    } else if (event.code == KEY_SPACE && event.value == INPUT_VAL_REPEAT) {
      if (state == SPACE_HELD) {
        if (DUR_MILLIS(space_held_start, event.time) >= 200) {
          WRITE_EVENTS(&space_down, &noop_up);

          state = SPACE_IS_SPACE;
        }
        continue;
      }
    } else if (event.code == KEY_SPACE && event.value == INPUT_VAL_RELEASE) {
      switch (state) {
      case START:
        break;
      case SPACE_HELD:
        WRITE_EVENTS(&space_down, &noop_up, &space_up,
                     is_key_buffered ? &buffered_key_event : NULL);
        is_key_buffered = false;
        state = START;
        continue;
      case SPACE_IS_SPACE:
        WRITE_EVENTS(is_key_buffered ? &buffered_key_event : NULL, &space_up);
        is_key_buffered = false;
        state = START;
        continue;
      case SPACE_IS_REALLY_SPACE:
        write_event(&event);

        state = START;
        continue;
      case SPACE_IS_META:
        write_event(&meta_up);

        state = START;
        continue;
      }
    } else if (event.code == KEY_ESC && event.value == INPUT_VAL_PRESS) {
      // Escape hatch: if ESC is pressed, just reset our state machine.
      WRITE_EVENTS(&event, (state == SPACE_HELD ? &noop_up : NULL));
      keys_held_count = 0;
      is_key_buffered = false;
      state = START;
      continue;
    } else if (event.value == INPUT_VAL_RELEASE) {
      switch (state) {
      case START:
      case SPACE_IS_META:
      case SPACE_IS_REALLY_SPACE:
        break;
      case SPACE_IS_SPACE:
        WRITE_EVENTS(&meta_down, is_key_buffered ? &buffered_key_event : NULL,
                     &event, // emit that original key release event
                     &space_up);
        is_key_buffered = false;
        state = SPACE_IS_META;
        continue;
      case SPACE_HELD:
        WRITE_EVENTS(&meta_down, &noop_up,
                     is_key_buffered ? &buffered_key_event : NULL,
                     &event // emit that original key release event
        );
        is_key_buffered = false;
        state = SPACE_IS_META;
        continue;
      }
    } else if (event.value == INPUT_VAL_PRESS) {
      switch (state) {
      case START:
      case SPACE_IS_META:
      case SPACE_IS_REALLY_SPACE:
        break;
      case SPACE_IS_SPACE:
      case SPACE_HELD:
        if (is_key_buffered) {
          // Oh boy, we already had one key buffered. This is too much to keep
          // track off. Let's just chord and stop buffering keys.
          WRITE_EVENTS(&meta_down, &buffered_key_event, &event);
          is_key_buffered = false;

          state = SPACE_IS_META;
          continue;
        } else {
          // Hold onto this key press event for now. We'll decide later if it
          // should get chorded with meta, or just emitted normally.
          buffered_key_event = event;
          is_key_buffered = true;
          continue;
        }
      }
    }

    write_event(&event);
  }
}
